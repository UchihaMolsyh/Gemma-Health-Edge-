import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'litert_service.dart';

/// Provider for LiteRT state
final litertProvider = NotifierProvider<LiteRTNotifier, LiteRTState>(LiteRTNotifier.new);

/// LiteRT state
class LiteRTState {
  final bool isInitialized;
  final bool isLoading;
  final bool isProcessing;
  final LiteRTConfig? currentConfig;
  final List<LiteRTResult> lastResults;
  final String? error;
  final Map<String, dynamic> modelInfo;

  const LiteRTState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isProcessing = false,
    this.currentConfig,
    this.lastResults = const [],
    this.error,
    this.modelInfo = const {},
  });

  LiteRTState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isProcessing,
    LiteRTConfig? currentConfig,
    List<LiteRTResult>? lastResults,
    String? error,
    Map<String, dynamic>? modelInfo,
    bool clearError = false,
  }) {
    return LiteRTState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      currentConfig: currentConfig ?? this.currentConfig,
      lastResults: lastResults ?? this.lastResults,
      error: clearError ? null : (error ?? this.error),
      modelInfo: modelInfo ?? this.modelInfo,
    );
  }
}

/// LiteRT state notifier
class LiteRTNotifier extends Notifier<LiteRTState> {
  final LiteRTService _service = LiteRTService.instance;

  @override
  LiteRTState build() => const LiteRTState();

  /// Initialize with a model configuration
  Future<bool> initialize(LiteRTConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _service.initialize(config);

      if (success) {
        final info = _service.getModelInfo();
        state = state.copyWith(
          isInitialized: true,
          isLoading: false,
          currentConfig: config,
          modelInfo: info,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to initialize LiteRT model',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Initialization error: $e',
      );
      return false;
    }
  }

  /// Load a model from file path
  Future<bool> loadModel(String path,
      {LiteRTModelType type = LiteRTModelType.custom,
      List<String> labels = const [],
      int inputSize = 224}) async {
    final config = LiteRTConfig(
      modelPath: path,
      modelType: type,
      labels: labels,
      inputSize: inputSize,
    );
    return initialize(config);
  }

  /// Classify an image file
  Future<List<LiteRTResult>> classifyImageFile(String imagePath,
      {int topK = 5}) async {
    if (!state.isInitialized) {
      throw StateError('LiteRT not initialized');
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw FileSystemException('Image not found', imagePath);
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw FormatException('Failed to decode image');
      }

      // Preprocess image to input tensor
      final input = _preprocessImage(image);

      // Run inference
      final results = _service.classifyImage(input, topK: topK);

      state = state.copyWith(
        isProcessing: false,
        lastResults: results,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Classification error: $e',
      );
      return [];
    }
  }

  /// Classify image from bytes
  Future<List<LiteRTResult>> classifyImageBytes(Uint8List bytes,
      {int topK = 5}) async {
    if (!state.isInitialized) {
      throw StateError('LiteRT not initialized');
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw FormatException('Failed to decode image');
      }

      final input = _preprocessImage(image);
      final results = _service.classifyImage(input, topK: topK);

      state = state.copyWith(
        isProcessing: false,
        lastResults: results,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Classification error: $e',
      );
      return [];
    }
  }

  /// Classify text
  Future<List<LiteRTResult>> classifyText(String text, {int topK = 3}) async {
    if (!state.isInitialized) {
      throw StateError('LiteRT not initialized');
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final results = _service.classifyText(text, topK: topK);

      state = state.copyWith(
        isProcessing: false,
        lastResults: results,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Text classification error: $e',
      );
      return [];
    }
  }

  /// Preprocess image for model input
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final inputSize = state.currentConfig?.inputSize ?? 224;

    // Resize image
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to normalized tensor [batch, height, width, channels]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Download a model
  Future<String?> downloadModel(String url, String filename) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final path = await LiteRTService.downloadModel(url, filename);

      state = state.copyWith(isLoading: false);
      return path;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Download error: $e',
      );
      return null;
    }
  }

  /// Download Gemma 4 LiteRT model from HuggingFace
  Future<String?> downloadGemma4LiteRT() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final path = await LiteRTService.downloadGemma4LiteRT();

      if (path != null) {
        // Auto-load the downloaded model
        await loadModel(path, type: LiteRTModelType.custom);
      }

      state = state.copyWith(isLoading: false);
      return path;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Download error: $e',
      );
      return null;
    }
  }

  /// List available models
  Future<List<String>> listModels() async {
    return await LiteRTService.listAvailableModels();
  }

  /// Dispose and cleanup
  Future<void> disposeService() async {
    await _service.dispose();
    state = const LiteRTState();
  }

  void dispose() {
    _service.dispose();
  }
}
