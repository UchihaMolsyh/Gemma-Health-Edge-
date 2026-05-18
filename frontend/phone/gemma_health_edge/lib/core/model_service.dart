import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ModelService {
  static final ModelService _instance = ModelService._internal();
  static ModelService get instance => _instance;

  ModelService._internal();

  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _currentPhase = '';

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get currentPhase => _currentPhase;

  final String modelUrl = 'https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-IQ4_NL.gguf';
  final String modelFileName = 'gemma-4-E2B-it-IQ4_NL.gguf';

  String get llamaLibraryFileName {
    if (Platform.isAndroid) return 'libllama.so';
    if (Platform.isIOS) return 'libllama.dylib';
    if (Platform.isMacOS) return 'libllama.dylib';
    if (Platform.isWindows) return 'llama.dll';
    return 'libllama.so';
  }

  String get llamaLibraryUrl {
    if (Platform.isAndroid) {
      return 'https://huggingface.co/ggml-org/llama.cpp/resolve/main/android/arm64-v8a/libllama.so';
    }
    if (Platform.isIOS) {
      return 'https://huggingface.co/ggml-org/llama.cpp/resolve/main/ios/arm64/libllama.dylib';
    }
    if (Platform.isMacOS) {
      return 'https://huggingface.co/ggml-org/llama.cpp/resolve/main/macos/arm64/libllama.dylib';
    }
    if (Platform.isWindows) {
      return 'https://huggingface.co/ggml-org/llama.cpp/resolve/main/windows/amd64/llama.dll';
    }
    return 'https://huggingface.co/ggml-org/llama.cpp/resolve/main/linux/amd64/libllama.so';
  }

  Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/models/$modelFileName';
  }

  Future<String> getLibraryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/llama/$llamaLibraryFileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final f = File(path);
    return await f.exists() && f.lengthSync() > 1000000;
  }

  Future<bool> isLibraryDownloaded() async {
    final path = await getLibraryPath();
    final f = File(path);
    return await f.exists() && f.lengthSync() > 100000;
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function(bool, String?) onComplete,
  }) async {
    try {
      _downloadProgress = 0;
      _currentPhase = 'Downloading AI model...';

      final path = await getModelPath();
      final file = File(path);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(modelUrl));
      request.headers['User-Agent'] = 'GemmaHealthEdge/2.0';
      final response = await client.send(request);

      if (response.statusCode == 302 || response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null || redirectUrl.isEmpty) {
          onComplete(false, 'Redirect with no location');
          return;
        }
        final redirectResp = await client.send(http.Request('GET', Uri.parse(redirectUrl)));
        await _pipeStream(redirectResp, file, onProgress, onComplete);
      } else if (response.statusCode == 200) {
        await _pipeStream(response, file, onProgress, onComplete);
      } else {
        onComplete(false, 'Server returned status ${response.statusCode}');
      }
    } catch (e) {
      onComplete(false, e.toString());
    }
  }

  Future<void> downloadLlamaLibrary({
    required Function(double) onProgress,
    required Function(bool, String?) onComplete,
  }) async {
    try {
      _currentPhase = 'Downloading llama.cpp engine...';

      final path = await getLibraryPath();
      final file = File(path);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(llamaLibraryUrl));
      request.headers['User-Agent'] = 'GemmaHealthEdge/2.0';
      final response = await client.send(request);

      if (response.statusCode == 302 || response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null || redirectUrl.isEmpty) {
          onComplete(false, 'Redirect with no location');
          return;
        }
        final redirectResp = await client.send(http.Request('GET', Uri.parse(redirectUrl)));
        await _pipeStream(redirectResp, file, onProgress, onComplete);
      } else if (response.statusCode == 200) {
        await _pipeStream(response, file, onProgress, onComplete);
      } else {
        onComplete(false, 'Server returned status ${response.statusCode}');
      }
    } catch (e) {
      onComplete(false, e.toString());
    }
  }

  Future<void> downloadAll({
    required Function(String phase, double progress) onProgress,
    required Function(bool success, String? error) onComplete,
  }) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0;

    try {
      onProgress('Downloading llama.cpp engine...', 0);
      await downloadLlamaLibrary(
        onProgress: (p) => onProgress('Downloading llama.cpp engine...', p * 0.1),
        onComplete: (success, error) {
          if (!success) {
            debugPrint('[ModelService] Library download failed: $error');
          }
        },
      );

      onProgress('Downloading AI model...', 0.1);
      await downloadModel(
        onProgress: (p) => onProgress('Downloading AI model...', 0.1 + p * 0.9),
        onComplete: (success, error) {
          _isDownloading = false;
          if (success) {
            onComplete(true, null);
          } else {
            onComplete(false, error);
          }
        },
      );
    } catch (e) {
      _isDownloading = false;
      onComplete(false, e.toString());
    }
  }

  Future<void> _pipeStream(
    http.StreamedResponse response,
    File file,
    Function(double) onProgress,
    Function(bool, String?) onComplete,
  ) async {
    try {
      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          _downloadProgress = downloadedBytes / contentLength;
          onProgress(_downloadProgress);
        }
      }

      await sink.close();
      onComplete(true, null);
    } catch (e) {
      onComplete(false, e.toString());
    }
  }

  Future<void> deleteModel() async {
    final modelPath = await getModelPath();
    final modelFile = File(modelPath);
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    final libPath = await getLibraryPath();
    final libFile = File(libPath);
    if (await libFile.exists()) {
      await libFile.delete();
    }
  }
}
