import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A single RAG search result.
class RagResult {
  final String text;
  final String source;
  final double score;

  const RagResult({
    required this.text,
    required this.source,
    required this.score,
  });

  @override
  String toString() => 'RagResult(source: $source, score: $score)';
}

/// Offline CSV-based keyword search engine.
/// Ports the RAG engine from rag.js — inverted index over CSV datasets.
class RagService {
  /// Medical abbreviation allowlist — 2-char tokens allowed if in this list.
  static const List<String> medicalAllowlist = [
    'bp',
    'hr',
    'rr',
    'bmi',
    'rbc',
    'wbc',
    'ekg',
    'mri',
    'hiv',
    'als',
    'ibs',
    'ibd',
    'ms',
    'tb',
    'uv',
    'iv',
    'im',
    'po',
    'ldl',
    'hdl',
    'alt',
    'ast',
    'tsh',
    'psa',
  ];

  /// All loaded rows: [text, source]
  final List<List<String>> _rows = [];

  /// Inverted index: token → list of row indices
  final Map<String, List<int>> _index = {};

  bool _initialized = false;

  bool get isInitialized => _initialized;
  int get rowCount => _rows.length;

  // ─── Tokenizer ─────────────────────────────────────────────────────────

  /// Split text on non-alpha characters, lowercase.
  /// Keep tokens with length >= 3, OR in medical allowlist.
  List<String> tokenize(String str) {
    if (str.isEmpty) return [];

    final raw = str.toLowerCase().split(RegExp(r'[^a-zA-Z]+'));
    return raw.where((token) {
      if (token.isEmpty) return false;
      if (token.length >= 3) return true;
      return medicalAllowlist.contains(token);
    }).toList();
  }

  // ─── Index Builder ─────────────────────────────────────────────────────

  /// Load and index all CSV files from assets/datasets/.
  /// Call this once at app startup (on a background isolate if desired).
  ///
  /// Gracefully handles missing or malformed CSV files.
  /// Marks as initialized even if no datasets are found.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Read the asset manifest to find CSV files
      final assetFiles = await _discoverCsvAssets();

      if (assetFiles.isEmpty) {
        debugPrint('RAG: No CSV datasets found in assets/datasets/');
      }

      int loadedCount = 0;
      int failedCount = 0;

      for (final assetPath in assetFiles) {
        try {
          final csvString = await rootBundle.loadString(assetPath);
          final beforeCount = _rows.length;
          _parseCsv(csvString, assetPath);
          final afterCount = _rows.length;
          loadedCount++;
          debugPrint(
              'RAG: Loaded ${afterCount - beforeCount} rows from $assetPath');
        } catch (e) {
          failedCount++;
          debugPrint('RAG: Failed to load $assetPath: $e');
          continue;
        }
      }

      // Build inverted index
      _buildIndex();
      _initialized = true;
      debugPrint(
          'RAG: Initialized with ${_rows.length} rows from $loadedCount files ($failedCount failed)');
    } catch (e, stackTrace) {
      debugPrint('RAG: Initialization failed: $e\n$stackTrace');
      // If no datasets available, still mark as initialized
      _initialized = true;
    }
  }

  /// Parse a CSV string and append rows.
  ///
  /// Validates CSV structure and skips malformed rows.
  /// Limits total rows to prevent memory issues.
  void _parseCsv(String csvString, String source) {
    if (csvString.isEmpty) return;
    if (csvString.length > 5 * 1024 * 1024) {
      // 5MB limit per file
      debugPrint('RAG: CSV file too large, skipping: $source');
      return;
    }

    try {
      // Use csv package's convert function
      final csvParser = Csv(
        lineDelimiter: '\n',
        dynamicTyping: false,
      );
      final rows = csvParser.decode(csvString);

      if (rows.isEmpty) return;
      if (rows.length > 10000) {
        // Limit rows per file
        debugPrint(
            'RAG: CSV has too many rows (${rows.length}), limiting to 10000: $source');
      }

      // Skip header row, limit to 10000 rows total
      final maxRows = rows.length > 10000 ? 10000 : rows.length;
      for (int i = 1; i < maxRows; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // Concatenate all columns into a single searchable text
        final text = row.map((cell) => cell.toString().trim()).join(' | ');
        if (text.trim().isNotEmpty && text.length < 1000) {
          // Limit text length per row
          final fileName = source.split('/').last;
          _rows.add([text, fileName]);
        }
      }
    } catch (e) {
      // Skip malformed CSV files
      debugPrint('RAG: Failed to parse CSV from $source: $e');
    }
  }

  /// Build the inverted index from all loaded rows.
  void _buildIndex() {
    _index.clear();
    for (int i = 0; i < _rows.length; i++) {
      final tokens = tokenize(_rows[i][0]);
      final uniqueTokens = tokens.toSet();
      for (final token in uniqueTokens) {
        _index.putIfAbsent(token, () => []).add(i);
      }
    }
  }

  /// Discover CSV files in assets/datasets/.
  Future<List<String>> _discoverCsvAssets() async {
    final assets = <String>[];
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = _parseJsonManifest(manifestContent);

      for (final key in manifest.keys) {
        if (key.startsWith('assets/datasets/') && key.endsWith('.csv')) {
          assets.add(key);
        }
      }
    } catch (e) {
      // Failed to load manifest - will use fallback
    }

    // Fallback: try known health dataset names
    if (assets.isEmpty) {
      const commonNames = [
        'assets/datasets/health.csv',
        'assets/datasets/symptoms.csv',
        'assets/datasets/medications.csv',
        'assets/datasets/conditions.csv',
        'assets/datasets/first_aid.csv',
        'assets/datasets/nutrition.csv',
      ];
      for (final name in commonNames) {
        try {
          await rootBundle.loadString(name);
          assets.add(name);
        } catch (_) {}
      }
    }

    return assets;
  }

  Map<String, dynamic> _parseJsonManifest(String content) {
    try {
      return Map<String, dynamic>.from(json.decode(content));
    } catch (e) {
      debugPrint('RAG: Failed to parse manifest: $e');
      return {};
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────

  /// AND-first search (fix #4 from rag.js):
  /// 1. Try to find rows matching ALL query tokens
  /// 2. Fall back to scored OR search if AND yields < limit results
  ///
  /// Validates input and limits results to prevent performance issues.
  List<RagResult> search(String query, {int limit = 5}) {
    if (!_initialized || _rows.isEmpty) return [];
    if (query.isEmpty) return [];
    if (limit < 1 || limit > 20) {
      // Reasonable limits
      debugPrint('RAG: Invalid limit $limit, using default 5');
      limit = 5;
    }
    if (query.length > 500) {
      // Prevent excessively long queries
      debugPrint('RAG: Query too long, truncating to 500 chars');
      query = query.substring(0, 500);
    }

    final tokens = tokenize(query);
    if (tokens.isEmpty) return [];

    // ── Phase 1: AND search — intersection of all token postings ──
    final andResults = <int>[];
    Set<int>? intersection;

    for (final token in tokens) {
      final postings = _index[token];
      if (postings == null) {
        intersection = {};
        break;
      }
      if (intersection == null) {
        intersection = postings.toSet();
      } else {
        intersection = intersection.intersection(postings.toSet());
      }
    }

    if (intersection != null) {
      andResults.addAll(intersection);
    }

    if (andResults.length >= limit) {
      return andResults.take(limit).map((idx) {
        return RagResult(
          text: _rows[idx][0],
          source: _rows[idx][1],
          score: tokens.length.toDouble(), // Perfect score = all tokens matched
        );
      }).toList();
    }

    // ── Phase 2: OR search with scoring — fallback ──
    final scores = <int, double>{};

    for (final token in tokens) {
      final postings = _index[token];
      if (postings == null) continue;
      for (final idx in postings) {
        scores[idx] = (scores[idx] ?? 0) + 1.0;
      }
    }

    // Add AND results with boosted scores
    for (final idx in andResults) {
      scores[idx] = (scores[idx] ?? 0) + tokens.length;
    }

    // Sort by score descending
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) {
      return RagResult(
        text: _rows[entry.key][0],
        source: _rows[entry.key][1],
        score: entry.value,
      );
    }).toList();
  }
}
