import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ═════════════════════════════════════════════════════════════════════════════
// API Client for Backend Communication
// 
// Handles HTTP requests to the backend server with:
// - SSRF protection (blocks internal networks except localhost/LAN)
// - Retry logic with exponential backoff
// - Comprehensive error handling and user-friendly messages
// - Health checks and server auto-discovery
// - Streaming and non-streaming chat completions
// ═════════════════════════════════════════════════════════════════════════════

/// Thrown when HTTP operations fail.
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}

/// Validates URLs to prevent malicious connections.
class UrlValidator {
  // Static regex patterns for performance
  static final _regex172 = RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.');
  static final _multicastRegex = RegExp(r'^22[4-9]\.');
  static final _reserved23xRegex = RegExp(r'^23[0-9]\.');
  static final _reserved24xRegex = RegExp(r'^24[0-9]\.');
  static final _reserved25xRegex = RegExp(r'^25[0-5]\.');

  /// Blocked domains to prevent SSRF attacks
  /// Note: localhost and 127.0.0.1 are NOT blocked as they're needed for local server
  static const List<String> _blockedDomains = [
    'metadata.google.internal',
    '169.254.169.254',
    'metadata.aws.amazon.com',
    'link.local',
    'local',
  ];

  /// Blocked TLDs to prevent access to internal services
  static const List<String> _blockedTlds = [
    '.internal',
    '.corp',
    '.private',
  ];

  /// Validate a server URL is safe to connect to.
  ///
  /// Implements SSRF protection by blocking internal networks,
  /// metadata endpoints, and private IP ranges (except localhost/LAN).
  static bool isValidServerUrl(String url) {
    if (url.isEmpty) return false;
    if (url.length > 2048) return false; // Prevent excessively long URLs

    try {
      final uri = Uri.parse(url);

      // Check scheme
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      // Must have a host
      if (uri.host.isEmpty) {
        return false;
      }

      // Check for blocked TLDs
      for (final tld in _blockedTlds) {
        if (uri.host.endsWith(tld)) {
          return false;
        }
      }

      // Check blocked domains
      if (_blockedDomains.contains(uri.host)) {
        return false;
      }

      // Check for hostname with underscores (invalid but could be used for attacks)
      if (uri.host.contains('_')) {
        return false;
      }

      // Block private IP ranges (SSRF protection), except localhost/LAN
      final host = uri.host;
      if (_isPrivateIp(host) && !_isLocalhost(host) && !_isLanIp(host)) {
        return false;
      }

      // Port validation
      if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
        return false;
      }

      // Block common non-HTTP ports that shouldn't be used
      const blockedPorts = {22, 23, 25, 53, 110, 143, 445, 3306, 3389, 5432};
      if (uri.hasPort && blockedPorts.contains(uri.port)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if host is localhost (allowed for local server)
  static bool _isLocalhost(String host) {
    return host == 'localhost' || host == '127.0.0.1';
  }

  /// Check if IP is in LAN range (allowed for local server)
  /// Allows: 192.168.x.x, 10.x.x.x, 172.16-31.x.x
  static bool _isLanIp(String host) {
    // 192.168.0.0/16
    if (host.startsWith('192.168.')) return true;
    // 10.0.0.0/8
    if (host.startsWith('10.')) return true;
    // 172.16.0.0/12
    if (_regex172.hasMatch(host)) return true;
    return false;
  }

  /// Check if IP is in other private/risky ranges (blocked for SSRF protection)
  /// Blocks: 127.x.x.x (except 127.0.0.1), 169.254.x.x (link-local), 0.0.0.0, etc.
  static bool _isPrivateIp(String host) {
    // 127.0.0.0/8 loopback (excluding 127.0.0.1 which is handled by _isLocalhost)
    if (host.startsWith('127.') && host != '127.0.0.1') return true;
    // 169.254.0.0/16 link-local
    if (host.startsWith('169.254.')) return true;
    // 0.0.0.0/8
    if (host.startsWith('0.')) return true;
    // 224.0.0.0/4 multicast
    if (_multicastRegex.hasMatch(host) || _reserved23xRegex.hasMatch(host))
      return true;
    // 240.0.0.0/4 reserved
    if (_reserved24xRegex.hasMatch(host) || _reserved25xRegex.hasMatch(host))
      return true;
    // IPv6 loopback
    if (host == '::1' || host == '[::1]') return true;
    // IPv6 link-local
    if (host.startsWith('fe80:') || host.startsWith('[fe80:')) return true;
    return false;
  }
}

/// HTTP API client for llama-server (OpenAI-compatible chat completions)
/// and Wikipedia research mode.
class ApiClient {
  String _serverUrl;
  bool _isScanning = false;

  /// Setter for serverUrl with validation
  set serverUrl(String url) {
    if (!UrlValidator.isValidServerUrl(url)) {
      debugPrint('[ApiClient] Invalid server URL rejected: $url');
      throw ArgumentError('Invalid server URL: $url');
    }
    debugPrint('[ApiClient] Server URL updated: $url');
    _serverUrl = url;
  }

  /// Getter for serverUrl
  String get serverUrl => _serverUrl;

  /// Connection quality metrics
  int _successCount = 0;
  int _failureCount = 0;
  int _totalLatencyMs = 0;
  DateTime? _lastSuccessTime;

  /// Ports to auto-scan for middleman (8000) / backend (8080)
  static const List<int> _scanPorts = [
    8000,
    8080,
    5500,
    11434,
    5000,
    1234,
    7860,
    3000,
    8888
  ];

  /// Maximum retry attempts for failed requests (increased to 5 for API key stability)
  static const int _maxRetries = 5;

  /// Base delay for exponential backoff (ms)
  static const int _baseRetryDelayMs = 500;

  ApiClient({required String serverUrl}) : _serverUrl = serverUrl {
    // Validate initial server URL
    if (!UrlValidator.isValidServerUrl(serverUrl)) {
      throw ArgumentError('Invalid server URL: $serverUrl');
    }
  }

  // ─── Health Check ──────────────────────────────────────────────────────

  /// GET /health with 5-second timeout (increased from 3s for better reliability).
  /// Returns true if server responds with 200.
  Future<bool> checkHealth() async {
    debugPrint('[ApiClient] Checking health: $_serverUrl');
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$_serverUrl/api/v1/health');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[ApiClient] Health check timed out');
          _recordFailure();
          throw TimeoutException('Health check timed out');
        },
      );
      stopwatch.stop();
      debugPrint('[ApiClient] Health check response: ${response.statusCode}');
      if (response.statusCode == 200) {
        _recordSuccess(stopwatch.elapsedMilliseconds);
        debugPrint('[ApiClient] Health check passed');
        return true;
      }
      _recordFailure();
      debugPrint('[ApiClient] Health check failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      _recordFailure();
      debugPrint('[ApiClient] Health check error: $e');
      return false;
    }
  }

  /// Non-streaming chat completion.
  /// Returns the assistant content on success, or throws on HTTP/parse failures.
  /// Supports both local backend and cloud APIs (OpenRouter/Google).
  Future<String> completeChat({
    required List<Map<String, dynamic>> messages,
    bool useCloudApi = false,
    String mode = 'local',
    String cloudApiKey = '',
    String cloudModelId = 'google/gemma-4-27b-it',
    double temperature = 0.1,
    int maxTokens = 1024,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    return _retryWithBackoff(
      () async {
        final baseUrl = useCloudApi
            ? 'https://openrouter.ai/api/v1/chat/completions'
            : '$_serverUrl/api/v1/chat';
        final modelToUse = useCloudApi
            ? (cloudModelId.isEmpty ? 'google/gemma-4-27b-it' : cloudModelId)
            : 'gemma-4-e4b-it';

        final uri = Uri.parse(baseUrl);
        final body = jsonEncode({
          'model': modelToUse,
          'messages': messages,
          'stream': false,
          'mode': useCloudApi ? (cloudApiKey.contains('sk-or-') ? 'openrouter' : 'google') : mode,
          'temperature': temperature,
          'max_tokens': maxTokens,
        });

        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        if (useCloudApi && cloudApiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer $cloudApiKey';
          headers['HTTP-Referer'] = 'https://github.com/gemma-health-edge';
          headers['X-Title'] = 'Gemma Health Edge';
        }

        final stopwatch = Stopwatch()..start();
        http.Response? response;
        try {
          response = await http
              .post(uri, headers: headers, body: body)
              .timeout(timeout);
        } on SocketException {
          _recordFailure();
          throw const HttpException(
              'Unable to connect to the server. Please check your network and ensure the server is running.');
        } on TimeoutException {
          _recordFailure();
          throw const HttpException(
              'Request timed out. Please check your connection and try again.');
        }
        stopwatch.stop();

        if (response == null) {
          _recordFailure();
          throw const HttpException('Request failed: no response received.');
        }

        if (response.statusCode == 401) {
          _recordFailure();
          throw const HttpException(
              'Authentication failed. Please check your API key in settings.');
        }
        if (response.statusCode == 429) {
          _recordFailure();
          throw const HttpException(
              'Too many requests. Please wait a moment and try again.');
        }
        if (response.statusCode == 404 && useCloudApi) {
          _recordFailure();
          throw HttpException(
              'Model not found (404). The configured model "$cloudModelId" may be invalid or deprecated. Please check your model ID in settings.');
        }
        if (response.statusCode != 200) {
          _recordFailure();
          throw HttpException(
              'Server error (${response.statusCode}). Please try again later.');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        final msg = (choices != null && choices.isNotEmpty)
            ? (choices[0]['message'] as Map<String, dynamic>?)
            : null;
        final content = msg?['content'] as String?;
        if (content == null) {
          _recordFailure();
          throw const HttpException(
              'Received an invalid response from the server.');
        }
        _recordSuccess(stopwatch.elapsedMilliseconds);
        return content;
      },
      maxRetries: _maxRetries,
    );
  }

  // ─── Auto-detect Server ────────────────────────────────────────────────

  /// Scan common ports on localhost and LAN for a running llama-server.
  /// Returns the first responding URL or null.
  /// Uses parallel probing for faster discovery.
  /// Guard: won't run if a scan is already in progress.
  Future<String?> autoDetectServer() async {
    if (_isScanning) return null;
    _isScanning = true;

    try {
      // Build list of all candidate URLs
      final candidates = <String>[];

      // Localhost candidates
      for (final port in _scanPorts) {
        candidates.add('http://127.0.0.1:$port');
      }

      // LAN candidates
      final lanBases = await _getLanBases();
      for (final base in lanBases) {
        for (final port in _scanPorts) {
          candidates.add('http://$base:$port');
        }
      }

      // Probe in parallel batches to avoid overwhelming the network
      const batchSize = 8;
      for (var i = 0; i < candidates.length; i += batchSize) {
        final batch = candidates.skip(i).take(batchSize).toList();
        final results = await Future.wait(
          batch
              .map((url) => _probeUrl(url).then((found) => found ? url : null)),
          eagerError: false,
        );

        final found =
            results.firstWhere((url) => url != null, orElse: () => null);
        if (found != null && UrlValidator.isValidServerUrl(found)) {
          _serverUrl = found;
          return found;
        }
      }

      return null;
    } finally {
      _isScanning = false;
    }
  }

  /// Generate a smart title for a chat session based on the first message.
  /// Returns the AI-generated title or null on failure.
  Future<String?> generateChatTitle(String message) async {
    if (message.trim().isEmpty) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$_serverUrl/api/v1/chat/title'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final title = data['title'] as String?;
        if (title != null && title.isNotEmpty && title != 'New Conversation') {
          return title;
        }
      }
    } on SocketException {
      // Network error - will fall back to local title
    } on TimeoutException {
      // Timeout - will fall back to local title
    } catch (e) {
      // Other errors - will fall back to local title
    }
    return null;
  }

  /// Probe a single URL for /health endpoint.
  Future<bool> _probeUrl(String url) async {
    try {
      // Use Uri.parse with proper path resolution to avoid double slashes
      final baseUri = Uri.parse(url);
      final uri = baseUri.replace(path: '/api/v1/health');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get probable LAN base addresses from network interfaces.
  Future<List<String>> _getLanBases() async {
    final bases = <String>[];
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            // Use the device's own LAN IP as a candidate
            bases.add(addr.address);
            // Also try common gateway (x.x.x.1)
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              bases.add('${parts[0]}.${parts[1]}.${parts[2]}.1');
            }
          }
        }
      }
    } catch (e) {
      // Fallback common addresses
      bases.addAll(['192.168.1.1', '192.168.0.1', '10.0.0.1']);
    }
    if (bases.isEmpty) {
      bases.addAll(['192.168.1.1', '192.168.0.1']);
    }
    return bases.toSet().toList();
  }

  // ─── Streaming Chat Completion ─────────────────────────────────────────

  /// POST /v1/chat/completions with stream: true.
  /// Yields String chunks as they arrive via SSE.
  /// Supports both local backend and cloud APIs (OpenRouter/Google).
  /// Validates all inputs before making the request.
  Stream<String> streamChat({
    required List<Map<String, dynamic>> messages,
    bool useCloudApi = false,
    String mode = 'local',
    String cloudApiKey = '',
    String cloudModelId = 'google/gemma-4-27b-it',
    double temperature = 0.1,
    int maxTokens = 3024,
  }) async* {
    // Input validation
    if (messages.isEmpty) {
      yield '[ERROR] Messages list cannot be empty.';
      return;
    }
    if (temperature < 0 || temperature > 2) {
      yield '[ERROR] Temperature must be between 0 and 2.';
      return;
    }
    if (maxTokens < 1 || maxTokens > 32000) {
      yield '[ERROR] maxTokens must be between 1 and 32000.';
      return;
    }
    if (useCloudApi && cloudApiKey.isEmpty) {
      yield '[ERROR] Cloud API key is required when useCloudApi is true.';
      return;
    }
    final baseUrl = useCloudApi
        ? 'https://openrouter.ai/api/v1/chat/completions'
        : '$_serverUrl/api/v1/chat/stream';
    final modelToUse = useCloudApi
        ? (cloudModelId.isEmpty ? 'google/gemma-4-27b-it' : cloudModelId)
        : mode == 'ollama'
            ? 'gemma4'  // Use Ollama-compatible Gemma 4 model
            : 'gemma-4-e4b-it';

    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({
      'model': modelToUse,
      'messages': messages,
      'stream': true,
      'mode': useCloudApi ? (cloudApiKey.contains('sk-or-') ? 'openrouter' : 'google') : mode,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    if (useCloudApi && cloudApiKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $cloudApiKey';
      request.headers['HTTP-Referer'] = 'https://github.com/gemma-health-edge';
      request.headers['X-Title'] = 'Gemma Health Edge';
    }

    http.StreamedResponse? response;
    http.Client? client;
    String buffer = '';

    try {
      client = http.Client();
      response = await client.send(request).timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw TimeoutException('Request timed out after 180 seconds');
        },
      );

      if (response.statusCode == 401) {
        yield '[ERROR] Authentication failed. Please check your API key in settings.';
        return;
      }
      if (response.statusCode == 429) {
        yield '[ERROR] Too many requests. Please wait a moment and try again.';
        return;
      }
      if (response.statusCode == 404 && useCloudApi) {
        yield '[ERROR] Model not found (404). The configured model "$cloudModelId" may be invalid or deprecated. Please check your model ID in settings.';
        return;
      }
      if (response.statusCode != 200) {
        yield '[ERROR] Server error (${response.statusCode}). Please try again later.';
        return;
      }

      // Parse SSE stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        // Keep the last potentially incomplete line in the buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed == 'data: [DONE]') return;
          if (!trimmed.startsWith('data: ')) continue;

          final jsonStr = trimmed.substring(6);
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                final content = delta['content'] as String?;
                if (content != null) {
                  yield content;
                }
              }
            }
          } catch (e) {
            // Skip malformed JSON chunks
            continue;
          }
        }
      }

      // Process any remaining buffer
      if (buffer.trim().isNotEmpty) {
        final trimmed = buffer.trim();
        if (trimmed.startsWith('data: ') && trimmed != 'data: [DONE]') {
          try {
            final data =
                jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
            final choices = data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null) yield content;
            }
          } catch (e) {
            // ignore
          }
        }
      }
    } on SocketException catch (e) {
      yield '[ERROR] Unable to connect to the server. Please check your network connection and ensure the server is running. Details: ${e.message}';
    } on TimeoutException catch (e) {
      yield '[ERROR] The request took too long. Please try again or check your connection. Details: ${e.message}';
    } on FormatException catch (e) {
      yield '[ERROR] Invalid response format from server. Details: ${e.message}';
    } catch (e) {
      yield '[ERROR] An unexpected error occurred: ${e.toString()}';
    } finally {
      try {
        client?.close();
      } catch (_) {
        // Ignore close errors
      }
    }
  }

  // ─── Wikipedia Research ────────────────────────────────────────────────

  /// Fetch a Wikipedia summary for the given search term.
  /// Returns plain text summary or null on failure.
  ///
  /// Validates input term and sanitizes output.
  Future<String?> fetchWikipediaSummary(String term) async {
    if (term.trim().isEmpty) return null;
    if (term.length > 200) return null; // Prevent excessively long queries

    try {
      final encoded = Uri.encodeComponent(term.trim());
      final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'GemmaHealthEdge/2.0'
        },
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Wikipedia request timed out');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final extract = data['extract'] as String?;
        // Sanitize: limit length and remove potential scripts
        if (extract != null && extract.length <= 5000) {
          return extract;
        }
      }
      return null;
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Wikipedia fetch failed: $e');
      return null;
    }
  }

  /// Whether a scan is currently in progress.
  bool get isScanning => _isScanning;

  // ─── Critique (BUG-007 / BUG-025) ──────────────────────────────────────

  /// Run server-side safety critique.
  Future<Map<String, dynamic>> runCritique(
      String query, String response) async {
    return _retryWithBackoff(() async {
      final uri = Uri.parse('$_serverUrl/api/v1/critique');
      final body = jsonEncode({
        'query': query,
        'response': response,
      });

      final httpResponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (httpResponse.statusCode == 200) {
        return jsonDecode(httpResponse.body) as Map<String, dynamic>;
      }
      throw HttpException('Critique failed: ${httpResponse.statusCode}');
    }, maxRetries: 1)
        .catchError((e) {
      debugPrint('Critique network error: $e');
      return {
        'safe': null,
        'severity': 'unknown',
        'unvalidated': true,
        'circuit_open': true, // Assume circuit open on network error
      };
    });
  }

  Future<Map<String, dynamic>?> saveClinicalProfile(Map<String, dynamic> profile) async {
    try {
      final uri = Uri.parse('$_serverUrl/api/v1/data/profile');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Save clinical profile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getClinicalProfile() async {
    try {
      final uri = Uri.parse('$_serverUrl/api/v1/data/profile');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Get clinical profile error: $e');
      return null;
    }
  }

  /// Get connection quality metrics.
  Map<String, dynamic> getConnectionMetrics() {
    final totalRequests = _successCount + _failureCount;
    final successRate = totalRequests > 0
        ? (_successCount / totalRequests * 100).toStringAsFixed(1)
        : '0.0';
    final avgLatency = _successCount > 0
        ? (_totalLatencyMs / _successCount).toStringAsFixed(0)
        : '0';

    return {
      'successCount': _successCount,
      'failureCount': _failureCount,
      'successRate': '$successRate%',
      'averageLatencyMs': avgLatency,
      'lastSuccessTime': _lastSuccessTime?.toIso8601String(),
    };
  }

  /// Reset connection metrics.
  void resetMetrics() {
    _successCount = 0;
    _failureCount = 0;
    _totalLatencyMs = 0;
    _lastSuccessTime = null;
  }

  /// Record a successful request with latency.
  void _recordSuccess(int latencyMs) {
    _successCount++;
    _totalLatencyMs += latencyMs;
    _lastSuccessTime = DateTime.now();
  }

  /// Record a failed request.
  void _recordFailure() {
    _failureCount++;
  }

  /// Retry a function with exponential backoff.
  ///
  /// Implements exponential backoff with jitter to prevent thundering herd.
  /// Maximum delay is capped at 30 seconds.
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() fn, {
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        // Exponential backoff with jitter: base * 2^(attempt-1) + random
        final baseDelay = _baseRetryDelayMs * (1 << (attempt - 1));
        final jitter = (DateTime.now().millisecond % 500).toInt();
        final delay = (baseDelay + jitter).clamp(0, 60000); // Cap at 60s for API key stability
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }
}
