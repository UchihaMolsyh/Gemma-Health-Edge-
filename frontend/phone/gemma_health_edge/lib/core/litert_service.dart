import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// ═════════════════════════════════════════════════════════════════════════════
// LiteRT (TensorFlow Lite) Service for Flutter
// Provides on-device ML inference capabilities
// ═════════════════════════════════════════════════════════════════════════════

/// LiteRT model types supported by the service
enum LiteRTModelType {
  imageClassification,
  objectDetection,
  textClassification,
  poseEstimation,
  segmentation,
  custom,
}

/// LiteRT inference result
class LiteRTResult {
  final String label;
  final double confidence;
  final int index;
  final Map<String, dynamic>? metadata;

  const LiteRTResult({
    required this.label,
    required this.confidence,
    required this.index,
    this.metadata,
  });

  @override
  String toString() =>
      'LiteRTResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// LiteRT model configuration
class LiteRTConfig {
  final String modelPath;
  final LiteRTModelType modelType;
  final List<String> labels;
  final int inputSize;
  final int numThreads;
  final bool useGpuDelegate;
  final bool useNnApiDelegate;

  const LiteRTConfig({
    required this.modelPath,
    this.modelType = LiteRTModelType.custom,
    this.labels = const [],
    this.inputSize = 224,
    this.numThreads = 4,
    this.useGpuDelegate = false,
    this.useNnApiDelegate = false,
  });
}

/// LiteRT service for TensorFlow Lite inference
class LiteRTService {
  static LiteRTService? _instance;
  Interpreter? _interpreter;
  LiteRTConfig? _config;
  bool _isInitialized = false;

  LiteRTService._internal();

  /// Get singleton instance
  static LiteRTService get instance {
    _instance ??= LiteRTService._internal();
    return _instance!;
  }

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current config
  LiteRTConfig? get config => _config;

  // ───────────────────────────────────────────────────────────────────────────
  // Initialization
  // ───────────────────────────────────────────────────────────────────────────

  /// Initialize the LiteRT service with a model
  Future<bool> initialize(LiteRTConfig config) async {
    if (_isInitialized) {
      await dispose();
    }

    _config = config;

    try {
      // Check if model file exists
      final modelFile = File(config.modelPath);
      if (!await modelFile.exists()) {
        debugPrint('[LiteRT] Model not found: ${config.modelPath}');
        return false;
      }

      // Create interpreter options
      final options = InterpreterOptions()
        ..threads = config.numThreads;

      // Add delegates based on platform and config
      if (config.useGpuDelegate) {
        if (Platform.isAndroid) {
          options.addDelegate(GpuDelegateV2());
        } else if (Platform.isIOS) {
          options.addDelegate(GpuDelegate());
        }
      }

      if (config.useNnApiDelegate && Platform.isAndroid) {
        // NnApiDelegate is not available in current TFLite version, skipping
        debugPrint('[LiteRT] NnApiDelegate not available, skipping');
      }

      // Create interpreter
      _interpreter = await Interpreter.fromFile(
        modelFile,
        options: options,
      );

      // Verify interpreter is ready
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        debugPrint('[LiteRT] Model has no input or output tensors');
        await dispose();
        return false;
      }

      _isInitialized = true;
      debugPrint('[LiteRT] Initialized with model: ${config.modelPath}');
      debugPrint('[LiteRT] Inputs: ${inputTensors.map((t) => t.name).join(", ")}');
      debugPrint('[LiteRT] Outputs: ${outputTensors.map((t) => t.name).join(", ")}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[LiteRT] Initialization error: $e\n$stackTrace');
      await dispose();
      return false;
    }
  }

  /// Dispose and release resources
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _config = null;
    debugPrint('[LiteRT] Disposed');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Inference Methods
  // ───────────────────────────────────────────────────────────────────────────

  /// Run inference on input data
  /// Returns raw output tensors
  List<dynamic>? runInference(List<dynamic> input) {
    if (!_isInitialized || _interpreter == null) {
      throw StateError('LiteRT service not initialized');
    }

    try {
      // Validate input tensors
      final inputTensors = _interpreter!.getInputTensors();
      if (inputTensors.isEmpty) {
        debugPrint('[LiteRT] No input tensors available');
        return null;
      }

      // Check input shape compatibility
      for (var i = 0; i < inputTensors.length; i++) {
        final tensor = inputTensors[i];
        if (i < input.length) {
          final inputData = input[i];
          if (inputData is List) {
            final inputSize = inputData.fold<int>(1, (a, b) => a * (b is List ? b.length : 1));
            final tensorSize = tensor.shape.reduce((a, b) => a * b);
            if (inputSize != tensorSize) {
              debugPrint('[LiteRT] Input size mismatch at tensor $i: expected $tensorSize, got $inputSize');
              return null;
            }
          }
        }
      }

      // Get output tensor shapes
      final outputShapes = _interpreter!.getOutputTensors().map((t) => t.shape).toList();

      // Prepare output buffers
      final outputs = outputShapes.map((shape) {
        final size = shape.reduce((a, b) => a * b);
        return List<double>.filled(size, 0.0);
      }).toList();

      // Run inference
      _interpreter!.run(input, outputs);

      return outputs;
    } catch (e) {
      debugPrint('[LiteRT] Inference error: $e');
      return null;
    }
  }

  /// Run inference on a single input tensor
  List<double>? runSingleInference(List<dynamic> input) {
    final outputs = runInference(input);
    if (outputs != null && outputs.isNotEmpty) {
      return outputs.first.cast<double>();
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Image Classification
  // ───────────────────────────────────────────────────────────────────────────

  /// Classify an image (preprocessed as input tensor)
  List<LiteRTResult> classifyImage(List<List<List<List<double>>>> imageInput,
      {int topK = 5}) {
    if (!_isInitialized) {
      throw StateError('LiteRT service not initialized');
    }

    final output = runSingleInference(imageInput);
    if (output == null) return [];

    return _processClassificationOutput(output, topK);
  }

  /// Process raw classification output into sorted results
  List<LiteRTResult> _processClassificationOutput(List<double> output, int topK) {
    // Apply softmax if needed (assuming logits)
    final probabilities = _softmax(output);

    // Create indexed list for sorting
    final indexed = probabilities.asMap().entries.toList();

    // Sort by confidence descending
    indexed.sort((a, b) => b.value.compareTo(a.value));

    // Take top K
    final results = <LiteRTResult>[];
    for (var i = 0; i < topK && i < indexed.length; i++) {
      final entry = indexed[i];
      final label = _config!.labels.length > entry.key
          ? _config!.labels[entry.key]
          : 'Class ${entry.key}';

      results.add(LiteRTResult(
        label: label,
        confidence: entry.value,
        index: entry.key,
      ));
    }

    return results;
  }

  List<double> _softmax(List<double> input) {
    final maxVal = input.reduce((a, b) => a > b ? a : b);
    final expValues = input.map((x) => exp(x - maxVal)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Text Processing
  // ───────────────────────────────────────────────────────────────────────────

  /// Classify text sentiment/topic
  List<LiteRTResult> classifyText(String text, {int topK = 3}) {
    if (!_isInitialized) {
      throw StateError('LiteRT service not initialized');
    }

    // Simple word tokenization (for demo - use proper tokenizer in production)
    final tokens = _tokenize(text);

    // Run inference
    final output = runSingleInference([tokens]);
    if (output == null) return [];

    return _processClassificationOutput(output, topK);
  }

  List<double> _tokenize(String text) {
    // Simple character-level encoding for demo
    // In production, use a proper tokenizer like WordPiece/BPE
    final maxLen = 128;
    final tokens = List<double>.filled(maxLen, 0.0);

    for (var i = 0; i < text.length && i < maxLen; i++) {
      tokens[i] = text.codeUnitAt(i) / 255.0; // Normalize
    }

    return tokens;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Model Utilities
  // ───────────────────────────────────────────────────────────────────────────

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    if (_interpreter == null) {
      return {'status': 'not_initialized'};
    }

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    return {
      'status': 'initialized',
      'input_count': inputTensors.length,
      'output_count': outputTensors.length,
      'inputs': inputTensors.map((t) => {
            'name': t.name,
            'shape': t.shape,
            'type': t.type.toString(),
          }).toList(),
      'outputs': outputTensors.map((t) => {
            'name': t.name,
            'shape': t.shape,
            'type': t.type.toString(),
          }).toList(),
    };
  }

  /// Download a model from URL to app directory
  static Future<String?> downloadModel(String url, String filename) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final modelPath = '${appDir.path}/$filename';

      final file = File(modelPath);
      if (await file.exists()) {
        return modelPath; // Already downloaded
      }

      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        return modelPath;
      }

      return null;
    } catch (e) {
      debugPrint('[LiteRT] Download error: $e');
      return null;
    }
  }

  /// Download Gemma 4 LiteRT model from HuggingFace
  static Future<String?> downloadGemma4LiteRT() async {
    final filename = 'gemma-4-E2B-it-litert-lm.tflite';
    final url = 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-litert-lm.tflite';
    return downloadModel(url, filename);
  }

  /// List available models in app directory
  static Future<List<String>> listAvailableModels() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final dir = Directory(appDir.path);

      if (!await dir.exists()) return [];

      final files = await dir
          .list()
          .where((f) => f.path.endsWith('.tflite'))
          .map((f) => f.path)
          .toList();

      return files;
    } catch (e) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pre-trained Model Configurations
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-configured models for common use cases
class LiteRTModels {
  /// MobileNetV3 for image classification
  static LiteRTConfig get mobileNet => const LiteRTConfig(
        modelPath: 'assets/models/mobilenet_v3.tflite',
        modelType: LiteRTModelType.imageClassification,
        labels: [], // Load from labels.txt
        inputSize: 224,
        numThreads: 4,
        useGpuDelegate: true,
      );

  /// EfficientNet-Lite0 for image classification
  static LiteRTConfig get efficientNet => const LiteRTConfig(
        modelPath: 'assets/models/efficientnet_lite0.tflite',
        modelType: LiteRTModelType.imageClassification,
        labels: [],
        inputSize: 224,
        numThreads: 4,
        useGpuDelegate: true,
      );

  /// Health-specific model configuration
  static LiteRTConfig healthModel(String modelPath,
          {List<String> labels = const []}) =>
      LiteRTConfig(
        modelPath: modelPath,
        modelType: LiteRTModelType.imageClassification,
        labels: labels,
        inputSize: 224,
        numThreads: 2,
        useGpuDelegate: false, // Conservative for health data
      );
}
