import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'chat_provider.dart';


/// Chat message bubble widget.
/// User messages: right-aligned with accent color.
/// Assistant messages: left-aligned with surface color.
class MessageBubble extends ConsumerStatefulWidget {
  final String role;
  final String content;
  final String messageId;
  final String? imageBase64;
  final String? thinkingContent;
  final bool showThinking;
  final Color accentColor;

  final String? severity;
  final bool unvalidated;

  const MessageBubble({
    super.key,
    required this.role,
    required this.content,
    required this.messageId,
    this.imageBase64,
    this.thinkingContent,
    this.showThinking = true,
    required this.accentColor,
    this.severity,
    this.unvalidated = false,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _holoController;


  @override
  void initState() {
    super.initState();
    _holoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // Only run shimmer animation for assistant bubbles (saves CPU on user msgs)
    if (!isUser) {
      _holoController.repeat();
    }
  }

  @override
  void dispose() {
    _holoController.dispose();
    super.dispose();
  }

  bool get isUser => widget.role == 'user';
  Widget _buildMarkdown(BuildContext context, bool isDark) {
    return MarkdownBody(
      data: widget.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black),
          fontSize: 15,
        ),
        code: TextStyle(
          backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Long-press to copy on mobile — no need to hunt for the tiny button
        onLongPress: () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: widget.content));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          margin: EdgeInsets.only(
            left: isUser ? 48 : 8,
            right: isUser ? 8 : 48,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Thinking card — shown above bubble for assistant responses
              if (!isUser &&
                  widget.thinkingContent != null &&
                  widget.thinkingContent!.isNotEmpty &&
                  widget.showThinking)
                _buildThinkingCard(context, Theme.of(context).brightness == Brightness.dark),

              // Main bubble
              Container(
                decoration: BoxDecoration(
                  color: isUser
                      ? widget.accentColor.withOpacity(0.9)
                      : (isDark
                          ? const Color(0xFF121218)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _holoController,
                  builder: (context, child) {
                    if (isUser && widget.imageBase64 != null) {
                      try {
                        final imageBytes = base64Decode(widget.imageBase64!);
                        debugPrint('[MessageBubble] Displaying image, size: ${imageBytes.length} bytes');
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Hero(
                                tag: 'msg-img-${widget.messageId}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    imageBytes,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('[MessageBubble] Image display error: $error');
                                      return Container(
                                        width: 200,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                            const SizedBox(height: 8),
                                            Text('Image failed to load', 
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (widget.content.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: _buildMarkdown(context, isDark),
                              ),
                          ],
                        );
                      } catch (e) {
                        debugPrint('[MessageBubble] Failed to decode image: $e');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text('Invalid image', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.content.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: _buildMarkdown(context, isDark),
                              ),
                          ],
                        );
                      }
                    }
                    // User bubbles: skip the shader entirely
                    if (isUser) return child!;
                    // Map controller value [0,1] → shimmer center [0.2,0.8]
                    // so stops are always within [0.0,1.0] with no clamping needed
                    final sv = _holoController.value * 0.6 + 0.2;
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [sv - 0.2, sv, sv + 0.2],
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.0),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcOver,
                      child: child,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attached image
                      if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty)
                        _buildImage(),

                      // Safety Warning Badge
                      if (!isUser &&
                          (widget.severity == 'high' || widget.severity == 'critical'))
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: Colors.red.shade900.withOpacity(0.8),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'WARNING: Response flagged as potentially unsafe (${widget.severity}). Verify with a doctor.',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Unvalidated / Circuit Open Badge
                      if (!isUser &&
                          widget.unvalidated &&
                          widget.severity != 'high' &&
                          widget.severity != 'critical')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: Colors.orange.shade800.withOpacity(0.8),
                          child: const Row(
                            children: [
                              Icon(Icons.gpp_maybe,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'UNVERIFIED: Safety guardrails are currently degraded. Read with caution.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Text content
                      if (widget.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: isUser
                              ? SelectableText(
                                  widget.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                )
                              : MarkdownBody(
                                  data: widget.content,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.92)
                                          : Colors.black87,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    code: TextStyle(
                                      backgroundColor: isDark
                                          ? Colors.black26
                                          : Colors.grey.shade200,
                                      color: isDark
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF2563EB),
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    h1: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: TextStyle(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.black54,
                                    ),
                                    strong: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    em: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.85)
                                          : Colors.black87,
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.shade50,
                                      border: Border(
                                        left: BorderSide(
                                          color: widget.accentColor,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              // Action buttons below the bubble
              const SizedBox(height: 2),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildImage() {
    try {
      // Validate base64 size (max 10MB to prevent memory issues)
      const maxBase64Length = 10 * 1024 * 1024 * 4 ~/ 3; // ~10MB in base64
      if (widget.imageBase64!.length > maxBase64Length) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 60),
          width: double.infinity,
          color: Colors.grey.shade800,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Image too large',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      }

      final bytes = base64Decode(widget.imageBase64!);
      return Container(
        constraints: const BoxConstraints(maxHeight: 200),
        width: double.infinity,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 60,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildThinkingCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade300,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        initiallyExpanded: false,
        leading: Icon(
          Icons.psychology,
          size: 18,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        title: Text(
          'Thinking Process',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        children: [
          Text(
            widget.thinkingContent!,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isUser) ...[
            _buildActionButton(context, icon: Icons.copy, tooltip: 'Copy', onTap: () => _copyToClipboard(context)),
            const SizedBox(width: 4),
            _buildActionButton(context, icon: Icons.edit, tooltip: 'Edit', onTap: () => _editMessage(context)),
          ] else ...[
            _buildActionButton(context, icon: Icons.copy, tooltip: 'Copy', onTap: () => _copyToClipboard(context)),
            const SizedBox(width: 4),
            _buildActionButton(context, icon: Icons.refresh, tooltip: 'Regenerate', onTap: () => _regenerateMessage(context)),
            const SizedBox(width: 4),
            _buildActionButton(context, icon: Icons.thumb_up_outlined, tooltip: 'Helpful', onTap: () => _rateMessage(context, 'up')),
            const SizedBox(width: 4),
            _buildActionButton(context, icon: Icons.thumb_down_outlined, tooltip: 'Not Helpful', onTap: () => _rateMessage(context, 'down')),
          ],
        ],
      ),
    );
  }


  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }


  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _regenerateMessage(BuildContext context) {
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.regenerateMessage(widget.messageId);
  }

  void _editMessage(BuildContext context) {
    // Show dialog to edit message
    final TextEditingController controller = TextEditingController(text: widget.content);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final chatNotifier = ref.read(chatProvider.notifier);
                  chatNotifier.editMessage(widget.messageId, controller.text.trim());
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _rateMessage(BuildContext context, String rating) {
    // Send feedback to backend (similar to PC frontend)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback: $rating'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Typing indicator — three animated dots
class TypingIndicator extends StatefulWidget {
  final Color color;

  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 48, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, _) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
