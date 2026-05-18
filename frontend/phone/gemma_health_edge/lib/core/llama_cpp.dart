import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform, File;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
// llama.cpp FFI Bindings for Flutter
// 
// Provides Dart FFI bindings to llama.cpp C library for on-device LLM inference.
// Supports GGUF model loading, tokenization, and streaming text generation.
// Falls back to mock mode if native library is not found.
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// Type Definitions
// ─────────────────────────────────────────────────────────────────────────────

/// Pointer to a llama.cpp context (inference state)
typedef LlamaContextPointer = Pointer<Void>;

/// Pointer to a llama.cpp model (loaded weights)
typedef LlamaModelPointer = Pointer<Void>;

// Function signatures
typedef LlamaInitFromFileNative = LlamaModelPointer Function(Pointer<Utf8> modelPath, Pointer<LlamaContextParams> params);
typedef LlamaInitFromFile = LlamaModelPointer Function(Pointer<Utf8> modelPath, Pointer<LlamaContextParams> params);

typedef LlamaFreeModelNative = Void Function(LlamaModelPointer model);
typedef LlamaFreeModel = void Function(LlamaModelPointer model);

typedef LlamaInitFromModelNative = LlamaContextPointer Function(LlamaModelPointer model, Pointer<LlamaContextParams> params);
typedef LlamaInitFromModel = LlamaContextPointer Function(LlamaModelPointer model, Pointer<LlamaContextParams> params);

typedef LlamaFreeNative = Void Function(LlamaContextPointer ctx);
typedef LlamaFree = void Function(LlamaContextPointer ctx);

typedef LlamaTokenizeNative = Int32 Function(LlamaModelPointer model, Pointer<Utf8> text, Pointer<Int32> tokens, Int32 nMaxTokens, Bool addSpecial, Bool parseSpecial);
typedef LlamaTokenize = int Function(LlamaModelPointer model, Pointer<Utf8> text, Pointer<Int32> tokens, int nMaxTokens, bool addSpecial, bool parseSpecial);

typedef LlamaEvalNative = Int32 Function(LlamaContextPointer ctx, Pointer<Int32> tokens, Int32 nTokens, Int32 nPast, Int32 nThreads);
typedef LlamaEval = int Function(LlamaContextPointer ctx, Pointer<Int32> tokens, int nTokens, int nPast, int nThreads);

typedef LlamaDecodeNative = Int32 Function(LlamaContextPointer ctx, Pointer<LlamaBatch> batch);
typedef LlamaDecode = int Function(LlamaContextPointer ctx, Pointer<LlamaBatch> batch);

typedef LlamaGetLogitsNative = Pointer<Float> Function(LlamaContextPointer ctx, Int32 i);
typedef LlamaGetLogits = Pointer<Float> Function(LlamaContextPointer ctx, int i);

typedef LlamaGetNTokensNative = Int32 Function(LlamaContextPointer ctx);
typedef LlamaGetNTokens = int Function(LlamaContextPointer ctx);

typedef LlamaNVocabNative = Int32 Function(LlamaModelPointer model);
typedef LlamaNVocab = int Function(LlamaModelPointer model);

typedef LlamaNContextNative = Int32 Function(LlamaModelPointer model);
typedef LlamaNContext = int Function(LlamaModelPointer model);

typedef LlamaTokenEosNative = Int32 Function();
typedef LlamaTokenEos = int Function();

typedef LlamaTokenBosNative = Int32 Function();
typedef LlamaTokenBos = int Function();

typedef LlamaSampleNative = Int32 Function(LlamaContextPointer ctx, Pointer<LlamaTokenData> candidates, Int32 nCandidates, Int32 mirostat, Float mirostatTau, Float mirostatEta, Float temp, Float topP, Int32 topK, Pointer<Int32> minP, Int32 tfsZ, Int32 typicalP, Int32 seed);
typedef LlamaSample = int Function(LlamaContextPointer ctx, Pointer<LlamaTokenData> candidates, int nCandidates, int mirostat, double mirostatTau, double mirostatEta, double temp, double topP, int topK, Pointer<Int32> minP, int tfsZ, int typicalP, int seed);

typedef LlamaSampleTokenNative = Int32 Function(LlamaContextPointer ctx, Pointer<LlamaTokenData> candidates, Int32 nCandidates);
typedef LlamaSampleToken = int Function(LlamaContextPointer ctx, Pointer<LlamaTokenData> candidates, int nCandidates);

typedef LlamaSetTokenDataNative = Void Function(Pointer<LlamaTokenData> data, Pointer<Int32> tokens, Pointer<Float> logits, Int32 size);
typedef LlamaSetTokenData = void Function(Pointer<LlamaTokenData> data, Pointer<Int32> tokens, Pointer<Float> logits, int size);

typedef LlamaTokenToPieceNative = Int32 Function(LlamaModelPointer model, Int32 token, Pointer<Uint8> buf, Int32 length);
typedef LlamaTokenToPiece = int Function(LlamaModelPointer model, int token, Pointer<Uint8> buf, int length);

// ─────────────────────────────────────────────────────────────────────────────
// llama.cpp C Structures
// ─────────────────────────────────────────────────────────────────────────────

base class LlamaContextParams extends Struct {
  @Int32()
  external int nCtx;
  
  @Int32()
  external int nBatch;
  
  @Int32()
  external int nThreads;
  
  @Int32()
  external int nThreadsBatch;
  
  @Int32()
  external int ropeScalingType;
  
  @Float()
  external double ropeFreqBase;
  
  @Float()
  external double ropeFreqScale;
  
  @Int32()
  external int f16Kv;
  
  @Int32()
  external int logitAll;
  
  @Int32()
  external int embedding;
}

base class LlamaBatch extends Struct {
  @Int32()
  external int nTokens;
  
  @Int32()
  external int nAlloc;
  
  external Pointer<Int32> token;
  
  external Pointer<Float> embd;
  
  external Pointer<Int32> pos;
  
  external Pointer<Int32> nSeqId;
  
  external Pointer<Pointer<Int32>> seqId;
  
  @Int8()
  external int logits;
}

base class LlamaTokenData extends Struct {
  @Int32()
  external int id;
  
  @Float()
  external double logit;
  
  @Float()
  external double p;
}

class LlamaCppLibrary {
  static DynamicLibrary? _lib;
  static bool _loaded = false;
  static bool _mockMode = true;

  // Function pointers
  static LlamaInitFromFile? llama_init_from_file;
  static LlamaFreeModel? llama_free_model;
  static LlamaInitFromModel? llama_init_from_model;
  static LlamaFree? llama_free;
  static LlamaTokenize? llama_tokenize;
  static LlamaEval? llama_eval;
  static LlamaDecode? llama_decode;
  static LlamaGetLogits? llama_get_logits;
  static LlamaGetNTokens? llama_get_n_tokens;
  static LlamaNVocab? llama_n_vocab;
  static LlamaNContext? llama_n_ctx;
  static LlamaTokenEos? llama_token_eos;
  static LlamaTokenBos? llama_token_bos;
  static LlamaSample? llama_sample;
  static LlamaSampleToken? llama_sample_token;
  static LlamaSetTokenData? llama_set_token_data;
  static LlamaTokenToPiece? llama_token_to_piece;

  static bool get isLoaded => _loaded;
  static bool get isMockMode => _mockMode;

  static Future<bool> loadLibrary() async {
    if (_loaded) return true;

    final searchPaths = await _getSearchPaths();

    for (final path in searchPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          _lib = DynamicLibrary.open(path);
          if (_bindFunctions()) {
            _loaded = true;
            _mockMode = false;
            return true;
          }
        }
      } catch (e) {
        continue;
      }
    }

    _loaded = true;
    _mockMode = true;
    return false;
  }

  static Future<List<String>> _getSearchPaths() async {
    final paths = <String>[];

    // Downloaded library in app documents directory (from ModelService)
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (Platform.isAndroid) {
        paths.add('${directory.path}/llama/libllama.so');
      } else if (Platform.isIOS) {
        paths.add('${directory.path}/llama/libllama.dylib');
      } else if (Platform.isMacOS) {
        paths.add('${directory.path}/llama/libllama.dylib');
      } else if (Platform.isWindows) {
        paths.add('${directory.path}/llama/llama.dll');
      } else {
        paths.add('${directory.path}/llama/libllama.so');
      }
    } catch (_) {}

    if (Platform.isWindows) {
      paths.addAll([
        'llama.dll',
        'llama-server.dll',
        'bin/llama.dll',
        'build/Release/llama.dll',
        'C:/llama.cpp/build/release/llama.dll',
        'C:/llama.cpp/build/bin/Release/llama.dll',
        '../../../backend/llama-server/llama.dll',
        '../../../../backend/llama-server/llama.dll',
      ]);
    } else if (Platform.isMacOS) {
      paths.addAll([
        'libllama.dylib',
        'build/libllama.dylib',
        '/usr/local/lib/libllama.dylib',
        '/opt/homebrew/lib/libllama.dylib',
      ]);
    } else if (Platform.isAndroid) {
      paths.addAll([
        'libllama.so',
        'libllama-android.so',
        'data/data/com.example.gemma_health_edge/lib/libllama.so',
        '/data/local/tmp/libllama.so',
      ]);
    } else if (Platform.isIOS) {
      paths.addAll([
        'llama.framework/llama',
        'Frameworks/llama.framework/llama',
        '@executable_path/Frameworks/llama.framework/llama',
      ]);
    } else if (Platform.isLinux) {
      paths.addAll([
        'libllama.so',
        'build/libllama.so',
        '/usr/lib/libllama.so',
        '/usr/local/lib/libllama.so',
      ]);
    }
    return paths;
  }

  static bool _bindFunctions() {
    if (_lib == null) return false;

    try {
      llama_init_from_file = _lib!.lookupFunction<LlamaInitFromFileNative, LlamaInitFromFile>('llama_init_from_file');
      llama_free_model = _lib!.lookupFunction<LlamaFreeModelNative, LlamaFreeModel>('llama_free_model');
      llama_init_from_model = _lib!.lookupFunction<LlamaInitFromModelNative, LlamaInitFromModel>('llama_init_from_model');
      llama_free = _lib!.lookupFunction<LlamaFreeNative, LlamaFree>('llama_free');
      llama_tokenize = _lib!.lookupFunction<LlamaTokenizeNative, LlamaTokenize>('llama_tokenize');
      llama_eval = _lib!.lookupFunction<LlamaEvalNative, LlamaEval>('llama_eval');
      llama_decode = _lib!.lookupFunction<LlamaDecodeNative, LlamaDecode>('llama_decode');
      llama_get_logits = _lib!.lookupFunction<LlamaGetLogitsNative, LlamaGetLogits>('llama_get_logits');
      llama_get_n_tokens = _lib!.lookupFunction<LlamaGetNTokensNative, LlamaGetNTokens>('llama_n_tokens');
      llama_n_vocab = _lib!.lookupFunction<LlamaNVocabNative, LlamaNVocab>('llama_n_vocab');
      llama_n_ctx = _lib!.lookupFunction<LlamaNContextNative, LlamaNContext>('llama_n_ctx');
      llama_token_eos = _lib!.lookupFunction<LlamaTokenEosNative, LlamaTokenEos>('llama_token_eos');
      llama_token_bos = _lib!.lookupFunction<LlamaTokenBosNative, LlamaTokenBos>('llama_token_bos');
      llama_sample = _lib!.lookupFunction<LlamaSampleNative, LlamaSample>('llama_sample');
      llama_sample_token = _lib!.lookupFunction<LlamaSampleTokenNative, LlamaSampleToken>('llama_sample_token');
      llama_set_token_data = _lib!.lookupFunction<LlamaSetTokenDataNative, LlamaSetTokenData>('llama_set_token_data');
      llama_token_to_piece = _lib!.lookupFunction<LlamaTokenToPieceNative, LlamaTokenToPiece>('llama_token_to_piece');
      return true;
    } catch (e) {
      return false;
    }
  }
}

class LlamaCppContext {
  LlamaModelPointer? _model;
  LlamaContextPointer? _ctx;
  bool _initialized = false;
  int _nCtx = 2048;
  int _nVocab = 0;
  int _nThreads = 4;

  bool get isInitialized => _initialized;
  int get nCtx => _nCtx;
  int get nVocab => _nVocab;

  Future<bool> init({
    String? modelPath,
    int nCtx = 3072,
    int nBatch = 512,
    int nThreads = 4,
  }) async {
    if (!LlamaCppLibrary.isLoaded) {
      await LlamaCppLibrary.loadLibrary();
    }

    if (LlamaCppLibrary.isMockMode) {
      debugPrint('[LlamaCpp] WARNING: Running in MOCK MODE - native library not found');
      _initialized = true;
      return true;
    }

    // Try to resolve path from ModelService if not provided
    String finalPath = modelPath ?? '';
    if (finalPath.isEmpty) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        finalPath = '${directory.path}/models/gemma-4-E2B-it-IQ4_NL.gguf';
        if (!await File(finalPath).exists()) {
          // Try legacy model name
          finalPath = '${directory.path}/models/gemma-4-Q4_K_M.gguf';
          if (!await File(finalPath).exists()) {
            // Try assets path
            finalPath = 'assets/models/gemma-4-E2B-it-IQ4_NL.gguf';
            if (!await File(finalPath).exists()) {
              // Fallback to legacy path
              finalPath = 'models/gemma-4-E2B-it-IQ4_NL.gguf';
            }
          }
        }
      } catch (e) {
        finalPath = 'assets/models/gemma-4-E2B-it-IQ4_NL.gguf';
      }
    }

    debugPrint('[LlamaCpp] Attempting to load model from: $finalPath');

    if (LlamaCppLibrary.llama_init_from_file == null) {
      debugPrint('[LlamaCpp] ERROR: llama_init_from_file function not bound');
      return false;
    }

    try {
      final params = calloc<LlamaContextParams>();
      params.ref.nCtx = nCtx;
      params.ref.nBatch = nBatch;
      params.ref.nThreads = nThreads;
      params.ref.f16Kv = 1;

      final modelPathNative = finalPath.toNativeUtf8();
      _model = LlamaCppLibrary.llama_init_from_file!(modelPathNative, params);
      calloc.free(modelPathNative);

      if (_model == nullptr) {
        calloc.free(params);
        debugPrint('[LlamaCpp] Failed to load model from: $finalPath');
        _model = null;
        return false;
      }

      _nVocab = LlamaCppLibrary.llama_n_vocab!(_model!);
      _nCtx = LlamaCppLibrary.llama_n_ctx!(_model!);
      _nThreads = nThreads;

      _ctx = LlamaCppLibrary.llama_init_from_model!(_model!, params);
      calloc.free(params);

      if (_ctx == nullptr) {
        if (_model != null && LlamaCppLibrary.llama_free_model != null) {
          LlamaCppLibrary.llama_free_model!(_model!);
        }
        _model = null;
        calloc.free(params);
        debugPrint('[LlamaCpp] Failed to create context');
        return false;
      }

      _initialized = true;
      debugPrint('[LlamaCpp] Initialized successfully: vocab=$_nVocab, ctx=$_nCtx');
      return true;
    } catch (e) {
      debugPrint('[LlamaCpp] Init error: $e');
      dispose();
      return false;
    }
  }

  Future<List<int>> tokenize(String text, {bool addSpecial = true}) async {
    if (LlamaCppLibrary.isMockMode) {
      return text.split(' ').map((e) => e.hashCode % 32000).toList();
    }
    if (!_initialized || _model == null) {
      debugPrint('[LlamaCpp] Cannot tokenize: not initialized');
      return [];
    }

    try {
      final textNative = text.toNativeUtf8();
      final maxTokens = text.length * 2 + 256;
      final tokens = calloc<Int32>(maxTokens);
      
      final nTokens = LlamaCppLibrary.llama_tokenize!(
        _model!, textNative, tokens, maxTokens, addSpecial, true,
      );
      
      calloc.free(textNative);
      
      final result = <int>[];
      for (var i = 0; i < nTokens; i++) result.add(tokens[i]);
      calloc.free(tokens);
      debugPrint('[LlamaCpp] Tokenized: ${text.length} chars -> $nTokens tokens');
      return result;
    } catch (e) {
      debugPrint('[LlamaCpp] Tokenize error: $e');
      return [];
    }
  }

  Stream<String> streamInfer(String prompt, {int maxTokens = 256, double temperature = 0.7}) async* {
    if (LlamaCppLibrary.isMockMode) {
      yield '[ERROR] Native llama.cpp library not found. Please install the native library for your platform to use real AI inference.';
      yield '\n\nCurrent status: MOCK MODE';
      yield '\n\nTo fix this:';
      if (Platform.isAndroid) {
        yield '\n- Run: flutter pub get llama_cpp_dart';
        yield '\n- Place libllama.so in the app\'s native library directory';
      } else if (Platform.isIOS) {
        yield '\n- Run: flutter pub get llama_cpp_dart';
        yield '\n- Add llama.framework to the iOS project';
      } else if (Platform.isWindows) {
        yield '\n- Run: flutter pub get llama_cpp_dart';
        yield '\n- Place llama.dll in the app directory';
      } else if (Platform.isMacOS) {
        yield '\n- Run: flutter pub get llama_cpp_dart';
        yield '\n- Place libllama.dylib in the app directory';
      }
      return;
    }
    
    if (!_initialized || _ctx == null) {
      yield '[Error] LlamaCpp not initialized';
      return;
    }

    try {
      final tokens = await tokenize(prompt);
      if (tokens.isEmpty) {
        yield '[Error] Tokenization failed';
        return;
      }

      final eos = LlamaCppLibrary.llama_token_eos!();
      var nPast = 0;
      
      for (var i = 0; i < maxTokens; i++) {
        final batch = calloc<LlamaBatch>();
        batch.ref.nTokens = 1;
        batch.ref.logits = 1;
        
        final tokenPtr = calloc<Int32>();
        tokenPtr.value = tokens[nPast];
        batch.ref.token = tokenPtr;
        
        final posPtr = calloc<Int32>();
        posPtr.value = nPast;
        batch.ref.pos = posPtr;
        
        final seqIdPtr = calloc<Int32>();
        batch.ref.nSeqId = seqIdPtr;
        batch.ref.seqId = calloc<Pointer<Int32>>();
        batch.ref.seqId.value = seqIdPtr;

        if (LlamaCppLibrary.llama_decode!(_ctx!, batch) != 0) {
          calloc.free(batch);
          break;
        }

        final logits = LlamaCppLibrary.llama_get_logits!(_ctx!, 0);
        final nVocab = LlamaCppLibrary.llama_n_vocab!(_model!);
        
        final candidates = calloc<LlamaTokenData>(nVocab);
        int sampled;
        if (LlamaCppLibrary.llama_set_token_data != null && LlamaCppLibrary.llama_sample_token != null) {
          LlamaCppLibrary.llama_set_token_data!(candidates, nullptr, logits, nVocab);
          sampled = LlamaCppLibrary.llama_sample_token!(_ctx!, candidates, nVocab);
        } else {
          debugPrint('[LlamaCpp] Sampling functions not available');
          calloc.free(candidates);
          break;
        }
        
        calloc.free(tokenPtr);
        calloc.free(posPtr);
        calloc.free(seqIdPtr);
        calloc.free(batch.ref.seqId);
        calloc.free(candidates);
        calloc.free(batch);
        
        if (sampled == eos) break;
        
        tokens.add(sampled);
        nPast++;
        
        // Proper detokenization using llama_token_to_piece
        if (LlamaCppLibrary.llama_token_to_piece != null) {
          final buf = calloc<Uint8>(32);
          final n = LlamaCppLibrary.llama_token_to_piece!(_model!, sampled, buf, 32);
          if (n > 0) {
            final piece = utf8.decode(buf.asTypedList(n), allowMalformed: true);
            yield piece;
          }
          calloc.free(buf);
        } else {
          // Fallback to basic ASCII
          if (sampled >= 32 && sampled <= 126) {
            yield String.fromCharCode(sampled);
          } else if (sampled == 13) {
            yield '\n';
          }
        }
        
        // Add a small delay to prevent blocking the UI thread too much
        await Future.delayed(Duration.zero);
      }
    } catch (e) {
      yield '[Error] Inference: $e';
    }
  }

  Future<String> infer(String prompt, {int maxTokens = 100, double temperature = 0.7}) async {
    if (LlamaCppLibrary.isMockMode) {
      return '[ERROR] Native llama.cpp library not found. Please install the native library for your platform to use real AI inference.\n\nCurrent status: MOCK MODE\n\nTo fix this:\n- Run: flutter pub get llama_cpp_dart\n- Place the native library (llama.dll/libllama.so/libllama.dylib) in the app directory.';
    }
    if (!_initialized || _ctx == null) {
      debugPrint('[LlamaCpp] Cannot infer: not initialized');
      return '[ERROR] LlamaCpp not initialized. Call init() first.';
    }

    try {
      final tokens = await tokenize(prompt);
      if (tokens.isEmpty) {
        debugPrint('[LlamaCpp] Cannot infer: tokenization failed');
        return '';
      }

      if (LlamaCppLibrary.llama_token_eos == null || LlamaCppLibrary.llama_token_bos == null) {
        debugPrint('[LlamaCpp] Token functions not available');
        return '[ERROR] Token functions not available';
      }

      final eos = LlamaCppLibrary.llama_token_eos!();
      
      final result = StringBuffer();
      var nPast = 0;
      
      debugPrint('[LlamaCpp] Starting inference: ${tokens.length} tokens, max=$maxTokens');
      
      for (var i = 0; i < maxTokens; i++) {
        final batch = calloc<LlamaBatch>();
        batch.ref.nTokens = 1;
        batch.ref.logits = 1;
        
        final tokenPtr = calloc<Int32>();
        tokenPtr.value = tokens[nPast];
        batch.ref.token = tokenPtr;
        
        final posPtr = calloc<Int32>();
        posPtr.value = nPast;
        batch.ref.pos = posPtr;
        
        final seqIdPtr = calloc<Int32>();
        batch.ref.nSeqId = seqIdPtr;
        batch.ref.seqId = calloc<Pointer<Int32>>();
        batch.ref.seqId.value = seqIdPtr;

        if (LlamaCppLibrary.llama_decode!(_ctx!, batch) != 0) {
          debugPrint('[LlamaCpp] Decode failed at token $i');
          calloc.free(batch);
          break;
        }

        final logits = LlamaCppLibrary.llama_get_logits!(_ctx!, 0);
        final nVocab = LlamaCppLibrary.llama_n_vocab!(_model!);
        
        final candidates = calloc<LlamaTokenData>(nVocab);
        LlamaCppLibrary.llama_set_token_data!(candidates, nullptr, logits, nVocab);
        
        final sampled = LlamaCppLibrary.llama_sample_token!(_ctx!, candidates, nVocab);
        
        calloc.free(tokenPtr);
        calloc.free(posPtr);
        calloc.free(seqIdPtr);
        calloc.free(batch.ref.seqId);
        calloc.free(candidates);
        calloc.free(batch);
        
        if (sampled == eos) {
          debugPrint('[LlamaCpp] Reached EOS token');
          break;
        }
        
        tokens.add(sampled);
        nPast++;
        
        // Simple detokenization (would need proper tokenizer in production)
        result.writeCharCode(sampled % 128);
      }

      debugPrint('[LlamaCpp] Inference complete: ${result.length} chars generated');
      return result.toString();
    } catch (e) {
      debugPrint('[LlamaCpp] Inference error: $e');
      return '';
    }
  }

  void dispose() {
    if (_ctx != null && LlamaCppLibrary.llama_free != null) {
      LlamaCppLibrary.llama_free!(_ctx!);
      _ctx = null;
      debugPrint('[LlamaCpp] Context freed');
    }
    if (_model != null && LlamaCppLibrary.llama_free_model != null) {
      LlamaCppLibrary.llama_free_model!(_model!);
      _model = null;
      debugPrint('[LlamaCpp] Model freed');
    }
    _initialized = false;
  }
}

class LlamaCppService {
  static final LlamaCppService _instance = LlamaCppService._internal();
  static LlamaCppService get instance => _instance;

  LlamaCppService._internal();

  final _contexts = <String, LlamaCppContext>{};

  Future<LlamaCppContext> getContext({
    String id = 'default',
    String modelPath = '',
    int nCtx = 2048,
  }) async {
    if (!_contexts.containsKey(id)) {
      final ctx = LlamaCppContext();
      await ctx.init(modelPath: modelPath, nCtx: nCtx);
      _contexts[id] = ctx;
    }
    return _contexts[id]!;
  }

  void removeContext(String id) {
    final ctx = _contexts.remove(id);
    ctx?.dispose();
  }

  void disposeAll() {
    for (final ctx in _contexts.values) {
      ctx.dispose();
    }
    _contexts.clear();
  }
}
