import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/message.dart';
import '../../core/models/session.dart';
import '../../core/models/app_settings.dart';
import '../../core/storage_service.dart';
import '../../core/api_client.dart';
import '../../core/rag_service.dart';
import '../../core/greeting_service.dart';
import '../../core/emergency_service.dart';
import '../../core/llama_cpp.dart';

// Providers for local AI services
final llamaCppServiceProvider = Provider((ref) => LlamaCppService.instance);

// ─── System Prompt ──────────────────────────────────────────────────────────

const String baseSystemPrompt =
    '''You are Gemma Health Edge, a caring health information assistant running fully offline.
RULES:
1. You are NOT a doctor. Always remind users to consult a healthcare professional.
2. Provide clear, easy-to-understand health information.
3. For images: describe observations, list possible causes, suggest basic care, recommend a doctor visit.
4. Use step-by-step reasoning. Include a safety disclaimer at the end of medical responses.
5. NEVER diagnose diseases or prescribe medications.''';

String buildSystemPromptWithProfile(AppSettings settings) {
  final profile = settings;
  final parts = <String>[];
  
  if (profile.allergies.isNotEmpty) {
    parts.add('Allergies: ${profile.allergies}');
  }
  if (profile.conditions.isNotEmpty) {
    parts.add('Conditions: ${profile.conditions}');
  }
  if (profile.medications.isNotEmpty) {
    parts.add('Medications: ${profile.medications}');
  }
  if (profile.age != null) {
    parts.add('Age: ${profile.age}');
  }
  if (profile.weight != null) {
    parts.add('Weight: ${profile.weight}kg');
  }
  if (profile.clinicalNotes.isNotEmpty) {
    parts.add('Notes: ${profile.clinicalNotes}');
  }
  
  if (parts.isEmpty) {
    return baseSystemPrompt;
  }
  
  return '$baseSystemPrompt\n\nPatient Profile: ${parts.join(', ')}';
}

// ─── Safety Critic Regex Patterns (compiled once) ────────────────────────────

final _doseRegex =
    RegExp(r'\b\d+(?:\.\d+)?\s?(?:mg|g|mcg|µg|ml)\b', caseSensitive: false);
final _prescriptiveRegex = RegExp(
    r'\b(take|start|stop|increase|decrease|dose|dosage|prescribe)\b',
    caseSensitive: false);
// Absolute confidence terms (word boundaries for most, but 100% needs \B for end boundary)
final _absoluteTermsRegex = RegExp(
  r'\b(guarantee|definitely|certainly|always|never)\b',
  caseSensitive: false,
);
// 100% needs lookahead because % is not a word character
final _hundredPercentRegex = RegExp(r'\b100%(?!\w)', caseSensitive: false);
// "for sure" as a phrase
final _forSureRegex = RegExp(r'\bfor sure\b', caseSensitive: false);

// Static regex patterns for performance
final _nonWordCharsRegex = RegExp(r'[^\w\s]');
final _whitespaceRegex = RegExp(r'\s+');

// ─── Chat State ─────────────────────────────────────────────────────────────

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? streamingContent;
  final String? attachedImageBase64;
  final bool isOnline;
  final String serverStatus; // 'online'|'offline'|'checking'
  final String? thinkingContent;
  final bool showThinking;
  final List<Session> sessions;
  final String? currentSessionId;
  final bool researchUsed;
  final Map<String, dynamic>? connectionMetrics;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingContent,
    this.attachedImageBase64,
    this.isOnline = false,
    this.serverStatus = 'offline',
    this.thinkingContent,
    this.showThinking = true,
    this.sessions = const [],
    this.currentSessionId,
    this.researchUsed = false,
    this.connectionMetrics,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingContent,
    String? attachedImageBase64,
    bool? isOnline,
    String? serverStatus,
    String? thinkingContent,
    bool? showThinking,
    List<Session>? sessions,
    String? currentSessionId,
    bool? researchUsed,
    Map<String, dynamic>? connectionMetrics,
    bool clearStreamingContent = false,
    bool clearThinkingContent = false,
    bool clearAttachedImage = false,
    bool clearCurrentSession = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingContent: clearStreamingContent
          ? null
          : (streamingContent ?? this.streamingContent),
      attachedImageBase64: clearAttachedImage
          ? null
          : (attachedImageBase64 ?? this.attachedImageBase64),
      isOnline: isOnline ?? this.isOnline,
      serverStatus: serverStatus ?? this.serverStatus,
      thinkingContent: clearThinkingContent
          ? null
          : (thinkingContent ?? this.thinkingContent),
      showThinking: showThinking ?? this.showThinking,
      sessions: sessions ?? this.sessions,
      currentSessionId: clearCurrentSession
          ? null
          : (currentSessionId ?? this.currentSessionId),
      researchUsed: researchUsed ?? this.researchUsed,
      connectionMetrics: connectionMetrics ?? this.connectionMetrics,
    );
  }
}

// ─── Chat Notifier ──────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  late final StorageService _storage;
  late final ApiClient _apiClient;
  late final RagService _ragService;
  AppSettings _settings = const AppSettings();

  DateTime? _lastHealthCheckTime;
  static const Duration _healthCheckDebounce = Duration(seconds: 10);


  StreamSubscription<String>? _streamSubscription;

  final FlutterTts _tts = FlutterTts();

  @override
  ChatState build() {
    _storage = ref.read(storageServiceProvider);
    _apiClient = ref.read(apiClientProvider);
    _ragService = ref.read(ragServiceProvider);
    // Defer session loading to avoid circular dependency during build
    Future.microtask(() => _loadSessions());
    // Initialize TTS asynchronously - don't block constructor
    _initTts().catchError((_) {
      // TTS initialization failed (e.g., in tests) - voice is optional
    });
    return const ChatState();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      // TTS not available (e.g., in tests or unsupported platform)
      // Silently ignore - voice output is optional
    }
  }

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    try {
      _tts.stop();
    } catch (e) {
      // Ignore TTS errors on dispose
    }
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    // Catch bad URLs from user settings — invalid URL throws ArgumentError;
    // don't crash the provider, just log and keep the old URL.
    try {
      _apiClient.serverUrl = settings.serverUrl;
    } catch (e) {
      debugPrint('[ChatNotifier] Ignoring invalid server URL: ${settings.serverUrl}');
    }
    state = state.copyWith(showThinking: settings.showThinking);
  }

  void stopStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Finalize any partially-streamed content as a real message so the user
    // doesn't lose what was already rendered when they hit Stop.
    final partial = _cleanThinkingFromContent(state.streamingContent ?? '').trim();
    if (partial.isNotEmpty) {
      final stoppedMsg = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_stopped',
        role: 'assistant',
        content: '$partial\n\n*\u2014 Response stopped*',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, stoppedMsg],
        isStreaming: false,
        isLoading: false,
        clearStreamingContent: true,
      );
      _saveCurrentSession();
    } else {
      state = state.copyWith(
        isStreaming: false,
        isLoading: false,
        clearStreamingContent: true,
      );
    }
  }


  // ─── Session Management ─────────────────────────────────────────────────

  void _loadSessions() {
    final sessions = _storage.loadSessions();
    if (sessions.isNotEmpty && state.currentSessionId == null) {
      // Auto-load most recent session on app start
      final lastSession = sessions.first;
      state = state.copyWith(
        sessions: sessions,
        currentSessionId: lastSession.id,
        messages: lastSession.messages,
      );
    } else {
      state = state.copyWith(sessions: sessions);
    }
  }

  Future<void> _saveSessions() async {
    await _storage.saveSessions(state.sessions);
  }

  Future<void> _saveCurrentSession() async {
    if (state.messages.isEmpty) return;

    final sessionId = state.currentSessionId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final title = await _generateSessionTitle();

    final existingIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    final session = Session(
      id: sessionId,
      title: title,
      date: DateTime.now(),
      messages: List<Message>.from(state.messages),
    );

    final sessions = List<Session>.from(state.sessions);
    if (existingIndex >= 0) {
      sessions[existingIndex] = session;
    } else {
      sessions.insert(0, session);
    }

    state = state.copyWith(
      sessions: Session.enforceLimit(sessions),
      currentSessionId: sessionId,
    );
    await _saveSessions();
  }

  // Static fallback message to avoid creating new objects on every call
  static final Message _fallbackTitleMsg = Message(
    id: '',
    role: 'user',
    content: 'New Chat',
    timestamp: DateTime(2020),
  );

  Future<String> _generateSessionTitle() async {
    // Use the first user message to generate an AI title
    if (state.messages.isEmpty) return 'New Chat';

    final firstUserMsg = state.messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => _fallbackTitleMsg,
    );
    final content = firstUserMsg.content.trim();
    if (content.isEmpty) return 'New Chat';

    debugPrint(
        '[AutoTitle] Generating title for: ${content.substring(0, min(50, content.length))}...');

    // Try to get AI-generated title from backend
    try {
      final aiTitle = await _apiClient.generateChatTitle(content);
      debugPrint('[AutoTitle] API returned: $aiTitle');
      if (aiTitle != null && aiTitle.isNotEmpty) {
        return aiTitle;
      }
    } catch (e) {
      debugPrint('[AutoTitle] API error: $e');
      // Fall back to local title generation
    }

    // Fallback: use first 40 characters
    if (content.length <= 40) return content;
    return '${content.substring(0, 40)}...';
  }

  void loadSession(String sessionId) {
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () =>
          Session(id: '', title: '', date: DateTime.now(), messages: []),
    );
    if (session.id.isEmpty) return;

    state = state.copyWith(
      messages: List<Message>.from(session.messages),
      currentSessionId: session.id,
      isLoading: false,
      isStreaming: false,
      clearStreamingContent: true,
      clearThinkingContent: true,
      clearAttachedImage: true,
      researchUsed: false,
    );
  }

  Future<void> deleteSession(String sessionId) async {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != sessionId).toList(),
    );
    if (state.currentSessionId == sessionId) {
      state = state.copyWith(
        currentSessionId: null,
        messages: [],
      );
    }
    await _storage.deleteSession(sessionId);
    await _saveSessions();
  }

  void newSession() {
    if (state.messages.isNotEmpty) {
      _saveCurrentSession();
    }
    state = state.copyWith(
      messages: [],
      clearCurrentSession: true,
      clearStreamingContent: true,
      clearThinkingContent: true,
      clearAttachedImage: true,
      researchUsed: false,
      isLoading: false,
      isStreaming: false,
    );
  }

  void clearChat() {
    newSession();
  }

  // ─── Message Actions ─────────────────────────────────────────────────────

  Future<void> copyMessage(String messageId) async {
    final message = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => Message(
        id: '',
        role: 'user',
        content: '',
        timestamp: DateTime.now(),
      ),
    );
    
    if (message.content.isNotEmpty) {
      // Use Flutter's clipboard via the UI layer
      // This will be handled in the UI widget
    }
  }

  Future<void> regenerateMessage(String messageId) async {
    // Find the assistant message to regenerate
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    
    final message = state.messages[messageIndex];
    if (message.role != 'assistant') return;
    
    // Find the user message that prompted this response
    int userMessageIndex = messageIndex - 1;
    while (userMessageIndex >= 0 && state.messages[userMessageIndex].role != 'user') {
      userMessageIndex--;
    }
    
    if (userMessageIndex < 0) return;
    
    final userMessage = state.messages[userMessageIndex];
    
    // Remove the current assistant response
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages.removeAt(messageIndex);
    
    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: false,
      clearStreamingContent: true,
      clearThinkingContent: true,
    );
    
    // Resend the user message to get a new response
    await sendMessage(userMessage.content);
  }

  String exportSession() {
    if (state.messages.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('Gemma Health Edge - Session Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    for (final m in state.messages) {
      final time = m.timestamp.toLocal().toString().split(' ')[1].substring(0, 5);
      buffer.writeln('[$time] ${m.role.toUpperCase()}:');
      buffer.writeln(m.content.replaceAll(RegExp(r'<[^>]*>'), '').trim());
      buffer.writeln();
    }
    return buffer.toString();
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    
    final message = state.messages[messageIndex];
    if (message.role != 'user') return;
    
    // Update the message content
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages[messageIndex] = message.copyWith(content: newContent);
    
    // Remove all assistant messages that came after this user message
    while (updatedMessages.length > messageIndex + 1) {
      updatedMessages.removeLast();
    }
    
    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: false,
      clearStreamingContent: true,
      clearThinkingContent: true,
    );
    
    // Generate new response for the edited message
    await sendMessage(newContent);
  }

  // ─── Image Handling ─────────────────────────────────────────────────────

  Message _errorMsg(String content) => Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );

  Future<void> attachImage(XFile file) async {
    if (file.path.isEmpty) {
      state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] No file selected.')]);
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      const maxSize = 10 * 1024 * 1024;

      if (bytes.isEmpty) {
        state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Image file is empty.')]);
        return;
      }
      if (bytes.length > maxSize) {
        state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Image too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)}MB). Please select an image under 10MB.')]);
        return;
      }

      final ext = file.path.split('.').last.toLowerCase();
      if (!const ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Unsupported image format (.$ext). Please use JPG, PNG, GIF, or WebP.')]);
        return;
      }

      final base64 = base64Encode(bytes);
      if (base64.length > 20 * 1024 * 1024) {
        state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Encoded image too large. Please use a smaller image.')]);
        return;
      }
      state = state.copyWith(attachedImageBase64: base64);
    } on FileSystemException catch (e) {
      state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Failed to read image file: ${e.message}')]);
    } catch (e, stackTrace) {
      debugPrint('Failed to attach image: $e\n$stackTrace');
      state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Failed to attach image: $e')]);
    }
  }

  void removeImage() {
    state = state.copyWith(clearAttachedImage: true);
  }

  // ─── Server Status ─────────────────────────────────────────────────────

  Future<void> checkServerHealth() async {
    // Debounce: skip if checked within last 5 seconds
    final now = DateTime.now();
    if (_lastHealthCheckTime != null &&
        now.difference(_lastHealthCheckTime!) < _healthCheckDebounce) {
      return;
    }
    _lastHealthCheckTime = now;

    state = state.copyWith(serverStatus: 'checking');
    final isHealthy = await _apiClient.checkHealth();
    final metrics = _apiClient.getConnectionMetrics();
    state = state.copyWith(
      isOnline: isHealthy,
      serverStatus: isHealthy ? 'online' : 'offline',
      connectionMetrics: metrics,
    );
  }

  Future<String?> autoDetectServer() async {
    state = state.copyWith(serverStatus: 'checking');
    final url = await _apiClient.autoDetectServer();
    if (url != null) {
      state = state.copyWith(isOnline: true, serverStatus: 'online');
    } else {
      state = state.copyWith(isOnline: false, serverStatus: 'offline');
    }
    return url;
  }

  // ─── Send Message ──────────────────────────────────────────────────────
  
  Future<void> sendMessage(String text) async {
    // Prevent sending if already streaming
    if (state.isStreaming || state.isLoading) return;

    HapticFeedback.lightImpact();

    // Validate input
    final trimmedText = text.trim();
    final hasImage = state.attachedImageBase64 != null &&
        state.attachedImageBase64!.isNotEmpty;

    if (trimmedText.isEmpty && !hasImage) {
      return; // Don't send empty messages without images
    }

    if (trimmedText.length > 10000) {
      state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Message too long (${trimmedText.length} characters). Please limit your message to 10,000 characters.')]);
      return;
    }

    // Check for potential injection patterns
    if (const ['<script', 'javascript:', 'data:', 'vbscript:'].any((p) => trimmedText.toLowerCase().contains(p))) {
      state = state.copyWith(messages: [...state.messages, _errorMsg('[ERROR] Message contains potentially dangerous content and was blocked.')]);
      return;
    }

    // Create user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text.trim(),
      imageBase64: state.attachedImageBase64,
      timestamp: DateTime.now(),
    );

    // CRITICAL: Capture the attached image BEFORE clearing state.
    // state.copyWith(clearAttachedImage: true) below wipes it, so checking
    // state.attachedImageBase64 in the API messages loop would always be null.
    final imageBase64ForApi = state.attachedImageBase64;

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearAttachedImage: true,
      clearStreamingContent: true,
      clearThinkingContent: true,
      researchUsed: false,
    );

    // INSTANT EMERGENCY INTERCEPT (BUG-001/002/003)
    if (!hasImage && EmergencyService.isEmergency(trimmedText)) {
      final emergencyResponse = EmergencyService.getEmergencyResponse();

      final assistantMessage = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_emergency',
        role: 'assistant',
        content: emergencyResponse,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        isStreaming: false,
      );

      await _saveCurrentSession();

      if (_settings.enableVoice) {
        _tts
            .speak("Call emergency services immediately. Do not wait.")
            .catchError((_) {});
      }

      debugPrint('[Emergency] Instant crisis card sent for: $trimmedText');
      return;
    }

    // INSTANT GREETING RECOGNITION
    // Check if message is a simple greeting - respond instantly without AI
    if (!hasImage && GreetingService.isGreeting(trimmedText)) {
      final greetingResponse = GreetingService.getGreetingResponse();

      // Simulate brief delay for natural feel (100-300ms)
      await Future.delayed(
          Duration(milliseconds: 100 + DateTime.now().millisecond % 200));

      final assistantMessage = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_greeting',
        role: 'assistant',
        content: greetingResponse,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        isStreaming: false,
      );

      await _saveCurrentSession();

      // Voice output if enabled
      if (_settings.enableVoice) {
        _tts.speak(greetingResponse).catchError((e) {
          debugPrint('TTS error: $e');
          return null;
        });
      }

      debugPrint('[Greeting] Instant response sent for: $trimmedText');
      return;
    }

    // Build API messages
    final List<Map<String, dynamic>> apiMessages = [];
    
    // System prompt with clinical profile
    final enhancedSystemPrompt = buildSystemPromptWithProfile(_settings);
    apiMessages.add({'role': 'system', 'content': enhancedSystemPrompt});

    // RAG context injection
    bool usedRag = false;
    String ragContext = '';
    if (_ragService.isInitialized) {
      final results = _ragService.search(text, limit: 3);
      if (results.isNotEmpty) {
        usedRag = true;
        ragContext =
            '\n\n[Medical Reference Data]\n${results.map((r) => '• ${r.text}').join('\n')}';
        apiMessages.add({
          'role': 'system',
          'content': 'Reference health data for context:$ragContext'
        });
      }
    }

    // Wikipedia research
    bool usedResearch = false;
    if (_settings.enableResearch && state.isOnline) {
      try {
        // Extract key medical terms for research
        final searchTerm = _extractSearchTerm(text);
        if (searchTerm.isNotEmpty) {
          final summary = await _apiClient.fetchWikipediaSummary(searchTerm);
          if (summary != null && summary.isNotEmpty) {
            apiMessages.add({
              'role': 'system',
              'content': 'Wikipedia reference for context: $summary'
            });
            usedResearch = true;
          }
        }
      } catch (e) {
        // Research failed — continue without it
      }
    }

    // History messages
    final maxMessages = _settings.maxHistoryTurns * 2;
    final allMessages = state.messages;
    final startIdx = allMessages.length > maxMessages ? allMessages.length - maxMessages : 0;
    
    for (int i = startIdx; i < allMessages.length; i++) {
      final m = allMessages[i];
      // Use the captured image for the last user message in the turn
      if (i == allMessages.length - 1 && m.role == 'user' && imageBase64ForApi != null) {
        apiMessages.add({
          'role': 'user',
          'content': [
            { 'type': 'text', 'text': m.content.isEmpty ? 'Analyze this health image.' : m.content },
            { 'type': 'image_url', 'image_url': { 'url': 'data:image/jpeg;base64,$imageBase64ForApi' } }
          ]
        });
      } else {
        apiMessages.add({
          'role': m.role,
          'content': m.content,
        });
      }
    }

    state = state.copyWith(
      isStreaming: true,
      isLoading: false,
      researchUsed: usedResearch,
    );

    // Stream the response
    String fullContent = '';
    String thinkingBlock = '';
    bool inThinking = false;
    bool thinkingDone = false;
    bool hasError = false;
    final startTime = DateTime.now();

    // Cancel any existing subscription before starting new stream
    try {
      await _streamSubscription?.cancel();
    } catch (e) {
      // Ignore cancellation errors
    }
    _streamSubscription = null;

    try {
      final Stream<String> stream;
      if (_settings.useLocalOnDeviceAi) {
        // ON-DEVICE AI
        if (_settings.localAiType == 'llama_cpp') {
          final ctx = await ref.read(llamaCppServiceProvider).getContext(
            modelPath: '',
            nCtx: 2048,
          );
        
          if (!ctx.isInitialized) {
            throw Exception('Local AI model not initialized');
          }
        
          // Add clinical profile to prompt for local inference
          final enhancedPrompt = '$enhancedSystemPrompt\n\nUser: $text';
          stream = ctx.streamInfer(enhancedPrompt);
        } else {
          // LiteRT fallback for now (can be expanded to full LLM if model available)
          stream = Stream.value('I am currently optimizing your local clinical knowledge base. For immediate symptom analysis, I am utilizing my offline Llama engine. How can I assist you today?');
        }
      } else {
        // MIDDLEMAN / CLOUD API
        String mode = 'local';
        if (_settings.useOllama) {
          mode = 'ollama';
        } else if (_settings.useSubBackendE2B) {
          mode = 'sub_local';
        }

        stream = _apiClient.streamChat(
          messages: apiMessages,
          mode: mode,
          useCloudApi: _settings.useCloudApi,
          cloudApiKey: _settings.cloudApiKey,
          cloudModelId: _settings.cloudModelId,
        );
      }

      // SHOWCASE WATCHDOG: Safety timeout if stream hangs (increased to 120s for API key stability)
      final watchdog = Timer(const Duration(seconds: 120), () {
        if (state.isStreaming) {
          stopStreaming();
          debugPrint('[Watchdog] Stream timed out.');
        }
      });

      try {
        await for (final chunk in stream) {
          watchdog.cancel(); // Reset watchdog on every chunk
          if (chunk.startsWith('[ERROR]')) {
            _lastHealthCheckTime = null;
            checkServerHealth();
            final errorMsg = Message(
              id: '${DateTime.now().millisecondsSinceEpoch}_err',
              role: 'assistant',
              content: chunk,
              timestamp: DateTime.now(),
            );
            state = state.copyWith(
              messages: [...state.messages, errorMsg],
              isStreaming: false,
              clearStreamingContent: true,
            );
            await _saveCurrentSession();
            hasError = true;
            break;
          }

          fullContent += chunk;

          // Parse <thinking>...</thinking> blocks
          if (!thinkingDone) {
            if (fullContent.contains('<thinking>') && !inThinking) {
              inThinking = true;
            }
            if (inThinking) {
              final thinkStart = fullContent.indexOf('<thinking>');
              final thinkEnd = fullContent.indexOf('</thinking>');
              if (thinkEnd > thinkStart && thinkStart >= 0) {
                thinkingBlock =
                    fullContent.substring(thinkStart + 10, thinkEnd).trim();
                thinkingDone = true;
                inThinking = false;
                fullContent = fullContent.substring(0, thinkStart) +
                    fullContent.substring(thinkEnd + 11);
              } else if (thinkStart >= 0) {
                thinkingBlock = fullContent.substring(thinkStart + 10).trim();
              }
            }
          }

          // Update streaming state
          final visibleContent = _cleanThinkingFromContent(fullContent);
          state = state.copyWith(
            streamingContent: visibleContent.trim(),
            thinkingContent: thinkingBlock.isNotEmpty ? thinkingBlock : null,
          );
        }
      } finally {
        watchdog.cancel();
      }

      HapticFeedback.mediumImpact();
      if (hasError) return;

      // Log streaming duration for monitoring
      final duration = DateTime.now().difference(startTime);
      if (duration.inSeconds > 30) {
        debugPrint('Warning: Stream took ${duration.inSeconds}s to complete');
      }
    } on TimeoutException catch (e) {
      // If local server failed and cloud API is available, try fallback
      if (fullContent.isEmpty &&
          !_settings.useCloudApi &&
          _settings.cloudApiKey.isNotEmpty) {
        try {
          state = state.copyWith(
            streamingContent: 'Retrying with cloud API...',
          );

          String cloudContent = '';
          await for (final chunk in _apiClient.streamChat(
            messages: apiMessages,
            useCloudApi: true,
            cloudApiKey: _settings.cloudApiKey,
            cloudModelId: _settings.cloudModelId,
          )) {
            if (chunk.startsWith('[ERROR]')) {
              cloudContent = chunk;
              break;
            }
            cloudContent += chunk;
            state = state.copyWith(streamingContent: cloudContent.trim());
          }

          if (!cloudContent.startsWith('[ERROR]')) {
            fullContent = cloudContent;
          } else {
            fullContent = cloudContent; // Error from cloud already formatted
          }
        } catch (cloudError) {
          fullContent =
              '[ERROR] Both local and cloud API failed. Local: $e, Cloud: $cloudError';
        }
      } else if (fullContent.isEmpty) {
        fullContent = '[ERROR] Connection lost: $e';
      }
    } catch (e, stackTrace) {
      debugPrint('Streaming error: $e\n$stackTrace');
      // If local server failed and cloud API is available, try fallback
      if (fullContent.isEmpty &&
          !_settings.useCloudApi &&
          _settings.cloudApiKey.isNotEmpty) {
        try {
          state = state.copyWith(
            streamingContent: 'Retrying with cloud API...',
          );

          String cloudContent = '';
          await for (final chunk in _apiClient.streamChat(
            messages: apiMessages,
            useCloudApi: true,
            cloudApiKey: _settings.cloudApiKey,
            cloudModelId: _settings.cloudModelId,
          )) {
            if (chunk.startsWith('[ERROR]')) {
              cloudContent = chunk;
              break;
            }
            cloudContent += chunk;
            state = state.copyWith(streamingContent: cloudContent.trim());
          }

          if (!cloudContent.startsWith('[ERROR]')) {
            fullContent = cloudContent;
          } else {
            fullContent = cloudContent; // Error from cloud already formatted
          }
        } catch (cloudError) {
          fullContent =
              '[ERROR] Both local and cloud API failed. Local: $e, Cloud: $cloudError';
        }
      } else if (fullContent.isEmpty) {
        fullContent = '[ERROR] Connection lost: $e';
      }

      // Handle error messages (except those already handled during streaming)
      if (fullContent.startsWith('[ERROR]') && !hasError) {
        final errorMsg = Message(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          role: 'assistant',
          content: fullContent,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isStreaming: false,
          clearStreamingContent: true,
        );
        await _saveCurrentSession();
        return;
      }
    } finally {
      // Ensure streaming state is always reset
      if (state.isStreaming) {
        state = state.copyWith(
          isStreaming: false,
          isLoading: false,
        );
      }
    }

    // Finalize assistant message
    final finalContent = _cleanThinkingFromContent(fullContent).trim();
    if (finalContent.isNotEmpty) {
      var reviewedContent = applySafetyCritic(
        userText: text,
        assistantText: finalContent,
        researchUsed: usedResearch,
        ragUsed: usedRag,
      );

      // Optional server-side critique using /api/v1/critique
      String? severityLevel;
      bool isUnvalidated = false;

      if (_settings.enableServerCritic && state.isOnline) {
        final critiqueInfo =
            await _apiClient.runCritique(text, reviewedContent);

        severityLevel = critiqueInfo['severity'] as String?;
        if (critiqueInfo['circuit_open'] == true ||
            critiqueInfo['unvalidated'] == true) {
          isUnvalidated = true;
          severityLevel = 'unknown'; // Degraded mode
        }

        if (critiqueInfo['was_blocked'] == true) {
          final reason =
              critiqueInfo['block_reason'] as String? ?? 'Safety violation';
          reviewedContent =
              '[SAFETY REJECTED] $reason\n\nI cannot provide an answer to this. Please consult a healthcare professional.';
        }
      }

      final assistantMessage = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_asst',
        role: 'assistant',
        content: reviewedContent,
        timestamp: DateTime.now(),
        severity: severityLevel,
        unvalidated: isUnvalidated,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isStreaming: false,
        clearStreamingContent: true,
      );

      // Voice output if enabled (non-blocking)
      if (_settings.enableVoice && !reviewedContent.startsWith('[')) {
        // Limit voice output length to prevent very long TTS
        final voiceText = reviewedContent.length > 1000
            ? '${reviewedContent.substring(0, 1000)}...'
            : reviewedContent;
        _tts.speak(voiceText).catchError((e) {
          debugPrint('TTS error: $e');
          // Ignore TTS errors - don't block UI
          return null;
        });
      }
    } else {
      state = state.copyWith(
        isStreaming: false,
        clearStreamingContent: true,
      );
    }

    await _saveCurrentSession();
  }

  String applySafetyCritic({
    required String userText,
    required String assistantText,
    required bool researchUsed,
    required bool ragUsed,
  }) {
    var out = assistantText;
    final lowerUser = userText.toLowerCase();

    const emergencyTerms = [
      'chest pain',
      'pressure in chest',
      'shortness of breath',
      'can\'t breathe',
      'stroke',
      'face droop',
      'slurred speech',
      'seizure',
      'unconscious',
      'fainting',
      'heavy bleeding',
      'suicidal',
      'kill myself',
      'self harm',
    ];

    final emergency = emergencyTerms.any((t) => lowerUser.contains(t));

    final hasDose = _doseRegex.hasMatch(out);
    final hasPrescriptiveLanguage = _prescriptiveRegex.hasMatch(out);
    final medicationRisk = hasDose || hasPrescriptiveLanguage;

    // Replace absolute terms with safer alternatives
    out = out
        .replaceAllMapped(_absoluteTermsRegex, (match) {
          final word = match.group(0)!.toLowerCase();
          // guarantee, definitely, certainly -> likely
          // always, never -> often
          return (word == 'always' || word == 'never') ? 'often' : 'likely';
        })
        .replaceAllMapped(_hundredPercentRegex, (_) => 'likely')
        .replaceAllMapped(_forSureRegex, (_) => 'likely');

    final needsDisclaimer = !out.toLowerCase().contains('not a doctor') &&
        !out.toLowerCase().contains('healthcare professional') &&
        !out.toLowerCase().contains('medical advice');

    final extras = <String>[];
    if (emergency) {
      extras.add(
          'If you have severe symptoms or think this may be an emergency, contact local emergency services immediately.');
    }
    if (medicationRisk) {
      extras.add(
          'I can\'t prescribe medication or confirm doses. Please ask a licensed clinician or pharmacist before taking or changing any medicine.');
    }
    if (researchUsed || ragUsed) {
      extras.add(
          'This answer may include reference context; please verify key details with a trusted medical source or clinician.');
    }
    if (needsDisclaimer) {
      extras.add(
          'I\'m not a doctor. This is general information and not medical advice.');
    }

    if (extras.isEmpty) return out;

    final suffix = extras.map((e) => '- $e').join('\n');
    return '$out\n\n$suffix';
  }

  // Common medical abbreviations that should be included even with 2 chars
  static const _medicalAbbreviations = {
    'bp',
    'hr',
    'rr',
    'bmi',
    'rbc',
    'wbc',
    'ekg',
    'ecg',
    'mri',
    'ct',
    'hiv',
    'als',
    'ibs',
    'ibd',
    'ms',
    'tb',
    'iv',
    'im',
    'po',
    'ldl',
    'hdl',
    'alt',
    'ast',
    'tsh',
    'psa',
    'pt',
    'inr',
    'bun',
    'creat',
    'glu',
    'hgb',
    'hct',
  };
  
  String _cleanThinkingFromContent(String content) {
    if (content.isEmpty) return '';
    
    // Remove both <thinking>...</thinking> and <thought>...</thought> tags
    // and everything in between them.
    String result = content;
    
    final thinkRegex = RegExp(r'<(thinking|thought)>[\s\S]*?</\1>', caseSensitive: false);
    result = result.replaceAll(thinkRegex, '');
    
    // Also remove any unclosed tags at the end of the stream
    final openThinkRegex = RegExp(r'<(thinking|thought)>[\s\S]*$', caseSensitive: false);
    result = result.replaceAll(openThinkRegex, '');
    
    return result.trim();
  }

  String _extractSearchTerm(String text) {
    if (text.isEmpty) return '';

    final trimmed = text.trim();
    if (trimmed.length < 2) return '';
    if (trimmed.length > 200) return ''; // Prevent excessively long queries

    // Static regex for better performance
    final cleanText = trimmed.replaceAll(_nonWordCharsRegex, ' ').trim();

    if (cleanText.isEmpty) return '';

    final words = cleanText
        .split(_whitespaceRegex)
        .where((w) =>
            w.length >= 2 &&
            (_medicalAbbreviations.contains(w.toLowerCase()) || w.length > 2))
        .take(3)
        .toList();

    if (words.isEmpty) return '';
    return words.join(' ');
  }

  // Intentionally removed: _extract_text was dead code (snake_case, never called)

  String _buildLocalPrompt(List<Map<String, dynamic>> messages) {
    final buffer = StringBuffer();
    for (final m in messages) {
      final role = m['role'];
      final content = m['content'];
      String text = '';
      if (content is String) {
        text = content;
      } else if (content is List) {
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            text += part['text'];
          }
        }
      }
      
      if (role == 'system') {
        buffer.write('<start_of_turn>system\n$text<end_of_turn>\n');
      } else if (role == 'user') {
        buffer.write('<start_of_turn>user\n$text<end_of_turn>\n');
      } else {
        buffer.write('<start_of_turn>model\n$text<end_of_turn>\n');
      }
    }
    buffer.write('<start_of_turn>model\n');
    return buffer.toString();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(serverUrl: AppSettings.defaultServerUrl);
});

final ragServiceProvider = Provider<RagService>((ref) {
  return RagService();
});

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
