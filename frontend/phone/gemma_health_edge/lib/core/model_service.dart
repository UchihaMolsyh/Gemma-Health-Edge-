import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelService {
  static final ModelService _instance = ModelService._internal();
  static ModelService get instance => _instance;

  ModelService._internal();

  bool _isDownloading = false;
  double _downloadProgress = 0;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  final String modelUrl = 'https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-IQ4_NL.gguf';
  final String modelFileName = 'gemma-4-E2B-it-IQ4_NL.gguf';

  Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/models/$modelFileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final f = File(path);
    return await f.exists() && f.lengthSync() > 1000000;
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function(bool, String?) onComplete,
  }) async {
    if (_isDownloading) return;

    try {
      _isDownloading = true;
      _downloadProgress = 0;

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
          _isDownloading = false;
          return;
        }
        final redirectResp = await client.send(http.Request('GET', Uri.parse(redirectUrl)));
        await _pipeStream(redirectResp, file, onProgress, onComplete);
      } else if (response.statusCode == 200) {
        await _pipeStream(response, file, onProgress, onComplete);
      } else {
        onComplete(false, 'Server returned status ${response.statusCode}');
        _isDownloading = false;
      }
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
      _isDownloading = false;
      onComplete(true, null);
    } catch (e) {
      _isDownloading = false;
      onComplete(false, e.toString());
    }
  }

  Future<void> deleteModel() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
