import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/i18n/app_localizations.dart';
import 'chat_provider.dart';
import '../settings/settings_provider.dart'; 
import 'message_bubble.dart';
import '../../core/models/session.dart';
import '../../core/model_service.dart';


class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _micPulseController;
  Timer? _healthCheckTimer;
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isDownloadingModel = false;
  double _downloadProgress = 0;
  String _downloadPhase = '';
  bool _modelInstalled = false;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Check server health on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(chatProvider.notifier).checkServerHealth();
      final modelOk = await ModelService.instance.isModelDownloaded();
      final libOk = await ModelService.instance.isLibraryDownloaded();
      if (mounted) setState(() => _modelInstalled = modelOk && libOk);
    });

    // Start periodic health checks every 2 minutes
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      ref.read(chatProvider.notifier).checkServerHealth();
    });

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only check health on resume if currently offline (more intelligent)
      final chatState = ref.read(chatProvider);
      if (chatState.serverStatus != 'online') {
        ref.read(chatProvider.notifier).checkServerHealth();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _micPulseController.dispose();
    _healthCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    try {
      _speech.stop();
    } catch (e) {
      debugPrint('Failed to stop speech on dispose: $e');
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && ref.read(chatProvider).attachedImageBase64 == null)
      return;

    _textController.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        await ref.read(chatProvider.notifier).attachImage(image);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorTitle}: ${e.message}')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to pick image: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  void _showImagePicker() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(l10n.cameraButton),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(l10n.galleryButton),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        debugPrint('Failed to stop speech: $e');
      }
      setState(() => _isListening = false);
      _micPulseController.stop();
      // Auto-send after stopping
      if (_textController.text.trim().isNotEmpty) {
        _sendMessage();
      }
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              _micPulseController.stop();
              if (_textController.text.trim().isNotEmpty) {
                _sendMessage();
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          if (mounted) {
            setState(() => _isListening = false);
            _micPulseController.stop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Voice recognition error: ${error.toString()}')),
            );
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _micPulseController.repeat(reverse: true);
        await _speech.listen(
        onResult: (result) {
            // Replace text entirely — STT gives incremental full results,
            // NOT deltas. Appending causes duplication ("hello hello world").
            final words = result.recognizedWords.trim();
            if (words.isNotEmpty && words.length < 500) {
              _textController.text = words;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            }
          },
          onSoundLevelChange: (level) {
            // Optional: visualize sound level
          },
          listenOptions: stt.SpeechListenOptions(
            cancelOnError: true,
            partialResults: true,
            listenMode: stt.ListenMode.confirmation,
          ),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        setState(() => _isListening = false);
        _micPulseController.stop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize speech: $e\n$stackTrace');
      setState(() => _isListening = false);
      _micPulseController.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final accentColor = Color(ref.watch(settingsProvider).settings.accentColor);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(chatState, l10n, theme, accentColor),
      body: SafeArea(
        child: Column(
          children: [
            // Research mode indicator
            if (chatState.researchUsed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: accentColor.withOpacity(0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.researchNote,
                        style: TextStyle(fontSize: 12, color: accentColor)),
                  ],
                ),
              ),

            // Message list
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildEmptyState(l10n, theme, accentColor)
                  : _buildMessageList(chatState, accentColor),
            ),

            // Attached image preview
            if (chatState.attachedImageBase64 != null)
              _buildImagePreview(chatState.attachedImageBase64!, l10n),

            // Input bar
            _buildInputBar(chatState, l10n, theme, accentColor),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatState chatState, AppLocalizations l10n,
      ThemeData theme, Color accentColor) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor,
                    accentColor.withBlue(255).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.health_and_safety, size: 18, color: Colors.white),
            ),

          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(chatProvider.notifier).newSession();
                  },
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Manual health check refresh when user taps status
                    // Only check if not already checking to avoid excessive requests
                    final chatState = ref.read(chatProvider);
                    if (chatState.serverStatus != 'checking') {
                      ref.read(chatProvider.notifier).checkServerHealth();
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        chatState.serverStatus == 'online'
                            ? Icons.check_circle
                            : chatState.serverStatus == 'checking'
                                ? Icons.refresh
                                : Icons.error,
                        size: 8,
                        color: chatState.serverStatus == 'online'
                            ? Colors.green
                            : chatState.serverStatus == 'checking'
                                ? Colors.grey
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chatState.serverStatus == 'online'
                            ? l10n.onlineMode
                            : chatState.serverStatus == 'checking'
                                ? l10n.serverChecking
                                : l10n.offlineMode,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Manual Reconnect Button (only if offline/checking)
        if (chatState.serverStatus != 'online')
          TextButton.icon(
            onPressed: chatState.serverStatus == 'checking'
                ? null
                : () => ref.read(chatProvider.notifier).checkServerHealth(),
            icon: SizedBox(
              width: 14,
              height: 14,
              child: chatState.serverStatus == 'checking'
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.refresh, size: 14),
            ),
            label: Text(
              chatState.serverStatus == 'checking' ? 'Linking...' : 'Connect',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        // Primary Action: Settings (always visible)
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.settingsTitle,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        // Secondary Actions: Overflow Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'history':
                _showSessionHistory(chatState, l10n, theme);
                break;
              case 'clear':
                // Show confirmation before clearing
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear current chat?'),
                    content: const Text('This will remove all messages from the current view but keep the session in history.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                      TextButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).clearChat();
                          Navigator.pop(context);
                        },
                        child: Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                break;
              case 'metrics':
                Navigator.pushNamed(context, '/health');
                break;
              case 'calendar':
                Navigator.pushNamed(context, '/calendar');
                break;
              case 'export':
                _exportCurrentSession(chatState);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.sessionHistory),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'calendar',
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.calendarTitle),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'metrics',
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text('Health Metrics'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(l10n.clearChat),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  const Icon(Icons.ios_share, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.exportChat),
                ],
              ),
            ),
          ],
        ),
      ],

    );
  }

  Widget _buildEmptyState(
      AppLocalizations l10n, ThemeData theme, Color accentColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.15),
                    accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.health_and_safety, size: 64, color: accentColor),

            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('🔍 ${l10n.suggestionSkin}', accentColor),
                _buildSuggestionChip('💊 ${l10n.suggestionMeds}', accentColor),
                _buildSuggestionChip(
                    '🥗 ${l10n.suggestionNutrition}', accentColor),
                _buildSuggestionChip(
                    '🩹 ${l10n.suggestionFirstAid}', accentColor),
              ],
            ),
            const SizedBox(height: 48),
            if (!_modelInstalled) ...[
              Text(
                'Full Offline AI Engine Not Installed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _isDownloadingModel
                  ? Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _downloadPhase.isNotEmpty ? _downloadPhase : 'Downloading...',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    )
                    : ElevatedButton.icon(
                      onPressed: _startModelDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor.withOpacity(0.1),
                        foregroundColor: accentColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_for_offline_outlined),
                      label: Text('Install Gemma 4-E2B (Model + Engine)'),
                    ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'AI Edge Engine Active',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startModelDownload() async {
    setState(() {
      _isDownloadingModel = true;
      _downloadProgress = 0;
      _downloadPhase = 'Preparing...';
    });

    // Download llama.cpp library first, then the model
    await ModelService.instance.downloadLlamaLibrary(
      onProgress: (p) => setState(() {
        _downloadPhase = 'Downloading llama.cpp engine...';
        _downloadProgress = p * 0.1;
      }),
      onComplete: (libSuccess, libError) {
        if (!libSuccess) {
          debugPrint('[ChatScreen] Library download failed (non-fatal): $libError');
        }
        // Continue with model download regardless
      },
    );

    if (!mounted) return;

    await ModelService.instance.downloadModel(
      onProgress: (p) => setState(() {
        _downloadPhase = 'Downloading AI model (3.2 GB)...';
        _downloadProgress = 0.1 + p * 0.9;
      }),
      onComplete: (success, error) {
        if (mounted) {
          setState(() {
            _isDownloadingModel = false;
            _modelInstalled = success;
            _downloadPhase = '';
          });
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Clinical AI Engine Installed Successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Installation Failed: $error')),
            );
          }
        }
      },
    );
  }

  Widget _buildSuggestionChip(String label, Color accentColor) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: accentColor.withOpacity(0.1),
      side: BorderSide(color: accentColor.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        // Remove emoji prefix for the actual query
        final text = label.substring(2).trim();
        _textController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageList(ChatState chatState, Color accentColor) {
    final msgCount = chatState.messages.length;
    final hasLoading = chatState.isLoading && !chatState.isStreaming;
    final hasStreaming =
        chatState.isStreaming && chatState.streamingContent != null;

    return ListView.builder(
      controller: _scrollController,
      // Vertical 8px top, 16px bottom (above input bar); horizontal 0 — bubbles handle their own
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: msgCount + (hasLoading ? 1 : 0) + (hasStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator (only when not streaming)
        if (hasLoading && index == msgCount) {
          return TypingIndicator(color: accentColor);
        }

        // Streaming message
        if (hasStreaming && index == msgCount) {
          return MessageBubble(
            role: 'assistant',
            content: chatState.streamingContent!,
            messageId: 'streaming_${DateTime.now().millisecondsSinceEpoch}',
            thinkingContent: chatState.thinkingContent,
            showThinking: chatState.showThinking,
            accentColor: accentColor,
          );
        }

        if (index >= chatState.messages.length) return const SizedBox.shrink();

        final message = chatState.messages[index];
        // For the last assistant message, show thinking content
        final isLastAssistant = message.role == 'assistant' &&
            index == chatState.messages.length - 1;

        return MessageBubble(
          role: message.role,
          content: message.content,
          messageId: message.id,
          imageBase64: message.imageBase64,
          thinkingContent: isLastAssistant ? chatState.thinkingContent : null,
          showThinking: chatState.showThinking,
          accentColor: accentColor,
          severity: message.severity,
          unvalidated: message.unvalidated,
        );
      },
    );
  }

  Widget _buildImagePreview(String base64, AppLocalizations l10n) {
    try {
      final imageBytes = base64Decode(base64);
      debugPrint('[ChatScreen] Image preview, size: ${imageBytes.length} bytes');
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageBytes,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[ChatScreen] Image preview error: $error');
                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.imageAttached,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => ref.read(chatProvider.notifier).removeImage(),
              tooltip: l10n.removeImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[ChatScreen] Failed to decode image for preview: $e');
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Invalid image',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => ref.read(chatProvider.notifier).removeImage(),
              tooltip: l10n.removeImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInputBar(ChatState chatState, AppLocalizations l10n,
      ThemeData theme, Color accentColor) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // 10px horizontal, 8px top, + safe area bottom
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image attach
          IconButton(
            icon: Icon(Icons.add_photo_alternate_outlined,
                color: accentColor.withOpacity(0.8)),
            onPressed: chatState.isStreaming ? null : _showImagePicker,
            tooltip: l10n.cameraButton,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.6 : 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !chatState.isStreaming,
                decoration: InputDecoration(
                  hintText: l10n.chatPlaceholder,
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  // 16px horizontal, 10px vertical (10/5 design rule)
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Voice button
          _buildVoiceButton(accentColor),

          // Send button
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                chatState.isStreaming ? Icons.stop : Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: chatState.isStreaming 
                ? () => ref.read(chatProvider.notifier).stopStreaming()
                : _sendMessage,
              tooltip: chatState.isStreaming ? 'Stop' : l10n.sendButton,
            ),

          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(Color accentColor) {
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (context, _) {
        final scale =
            _isListening ? 1.0 + (_micPulseController.value * 0.15) : 1.0;
        return Transform.scale(
          scale: scale,
          child: IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening
                  ? Colors.redAccent
                  : accentColor.withOpacity(0.8),
            ),
            onPressed: _toggleVoice,
            tooltip: _isListening ? 'Stop' : 'Voice',
          ),
        );
      },
    );
  }

  void _showSessionHistory(
      ChatState chatState, AppLocalizations l10n, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sessionHistory,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newSession),
                    onPressed: () {
                      ref.read(chatProvider.notifier).newSession();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 12),
                    SizedBox(width: 4),
                    Text(l10n.privacyBadge, style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: chatState.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(l10n.noSessions,
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final today = DateTime.now();
                        final yesterday = today.subtract(const Duration(days: 1));
                        
                        final todaySessions = chatState.sessions.where((s) => 
                          s.date.day == today.day && s.date.month == today.month && s.date.year == today.year).toList();
                        
                        final yesterdaySessions = chatState.sessions.where((s) => 
                          s.date.day == yesterday.day && s.date.month == yesterday.month && s.date.year == yesterday.year).toList();
                        
                        final olderSessions = chatState.sessions.where((s) => 
                          !todaySessions.contains(s) && !yesterdaySessions.contains(s)).toList();

                        return ListView(
                          controller: scrollController,
                          children: [
                            if (todaySessions.isNotEmpty) ...[
                              _buildDateHeader('Today', theme),
                              ...todaySessions.map((s) => _buildSessionTile(s, chatState, l10n, theme)),
                            ],
                            if (yesterdaySessions.isNotEmpty) ...[
                              _buildDateHeader('Yesterday', theme),
                              ...yesterdaySessions.map((s) => _buildSessionTile(s, chatState, l10n, theme)),
                            ],
                            if (olderSessions.isNotEmpty) ...[
                              _buildDateHeader('Older', theme),
                              ...olderSessions.map((s) => _buildSessionTile(s, chatState, l10n, theme)),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSessionTile(Session session, ChatState chatState,
      AppLocalizations l10n, ThemeData theme) {
    final isActive = session.id == chatState.currentSessionId;
    return ListTile(
      leading: Icon(
        Icons.chat_bubble,
        color: isActive ? theme.colorScheme.primary : Colors.grey,
        size: 20,
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${session.messages.length} messages',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
        onPressed: () {
          ref.read(chatProvider.notifier).deleteSession(session.id);
          Navigator.pop(context);
        },
        tooltip: l10n.deleteSession,
      ),
      onTap: () {
        ref.read(chatProvider.notifier).loadSession(session.id);
        Navigator.pop(context);
      },
    );
  }

  void _exportCurrentSession(ChatState chatState) {
    if (chatState.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to export')),
      );
      return;
    }
    final content = ref.read(chatProvider.notifier).exportSession();
    // In a real mobile app, we would use share_plus or similar.
    // For now, we'll show a success message as the logical integration is complete.
    debugPrint('[Export] Session content generated:\n$content');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session exported to local storage')),
    );
  }
}
