// Seasons Chat Page — Global Version
// Design: Spacious, calm, breathable

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:seasons/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/message.dart';
import '../../../data/services/voice_service.dart';
import '../../../data/services/image_service.dart';
import '../../providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  const ChatPage({
    super.key,
    this.conversationId,
    this.initialPrompt,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Voice input
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  bool _voiceInitialized = false;

  // Image selection
  final List<String> _selectedImagePaths = [];

  // Guide cards
  bool _showGuideCards = false;
  int _guidePage = 0;

  @override
  void initState() {
    super.initState();
    _initVoice();
    _checkGuideCards();

    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).sendMessage(widget.initialPrompt!);
        _messageController.clear();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initVoice() async {
    final ok = await _voiceService.initialize();
    if (mounted) setState(() => _voiceInitialized = ok);
  }

  Future<void> _checkGuideCards() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_guide_cards_v2') ?? false;
    if (!hasSeen && mounted) {
      setState(() => _showGuideCards = true);
    }
  }

  Future<void> _dismissGuideCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_guide_cards_v2', true);
    if (mounted) setState(() => _showGuideCards = false);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImagePaths.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
    _selectedImagePaths.clear();

    _scrollToBottom();
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (_voiceService.lastWords.isNotEmpty && mounted) {
        setState(() => _messageController.text = _voiceService.lastWords);
      }
      if (mounted) setState(() => _isListening = false);
    } else {
      final ok = await _voiceService.startListening(
        onResult: (text) {
          if (mounted) setState(() => _messageController.text = text);
        },
      );
      if (ok && mounted) setState(() => _isListening = true);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final SelectedImage? image;
      if (source == ImageSource.camera) {
        image = await ImageService.takePhoto();
      } else {
        image = await ImageService.pickImage();
      }

      if (image != null && mounted) {
        setState(() => _selectedImagePaths.add(image!.path));
      }
    } catch (e) {
      debugPrint('Image pick failed: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: SeasonsColors.background,
      appBar: AppBar(
        backgroundColor: SeasonsColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios, size: 18, color: SeasonsColors.textPrimary),
        ),
        title: Text(
          'Companion',
          style: SeasonsTypography.titleLarge.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w400, // Light title, not bold
          ),
        ),
        centerTitle: true,
      ),
      body: _showGuideCards
          ? _buildGuideOverlay()
          : Column(
              children: [
                // Messages
                Expanded(child: _buildMessageList(chatState)),
                // Image preview
                if (_selectedImagePaths.isNotEmpty) _buildImagePreview(),
                // Quick question chips
                if (chatState.messages.length <= 1 && !chatState.isLoading)
                  _buildQuickQuestions(),
                // Input area
                _buildInputArea(chatState),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────────
  // Guide Overlay — PageView, 3 cards
  // ──────────────────────────────────────────────

  Widget _buildGuideOverlay() {
    final guideCards = [
      _GuideCardData(
        emoji: '💡',
        title: 'Wellness Questions',
        description: 'Ask anything about your\nwell-being and daily habits',
        color: SeasonsColors.surfaceVariant,
      ),
      _GuideCardData(
        emoji: '🍵',
        title: 'Try saying',
        description: '"What should I eat today?"\n"I feel a bit stressed"',
        color: SeasonsColors.softSageLight,
      ),
      _GuideCardData(
        emoji: '❤️',
        title: 'I remember you',
        description: 'Your preferences and habits\nshape better suggestions',
        color: SeasonsColors.warmSandLight,
      ),
    ];

    final controller = PageController();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: guideCards.length,
              onPageChanged: (index) => setState(() => _guidePage = index),
              itemBuilder: (context, index) {
                final card = guideCards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Text(card.emoji, style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 32),
                      Text(
                        card.title,
                        style: SeasonsTypography.headlineSmall.copyWith(
                          color: SeasonsColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card.description,
                        textAlign: TextAlign.center,
                        style: SeasonsTypography.bodyLarge.copyWith(
                          color: SeasonsColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Page indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(guideCards.length, (index) {
                return Container(
                  width: _guidePage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _guidePage == index
                        ? SeasonsColors.primary
                        : SeasonsColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _dismissGuideCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SeasonsColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _guidePage == guideCards.length - 1 ? 'Start Chatting' : 'Continue',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          if (_guidePage < guideCards.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: TextButton(
                onPressed: _dismissGuideCards,
                child: Text(
                  'Skip',
                  style: TextStyle(color: SeasonsColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Message List
  // ──────────────────────────────────────────────

  Widget _buildMessageList(dynamic chatState) {
    if (chatState.messages.isEmpty && !_showGuideCards) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Your companion is here',
              style: SeasonsTypography.titleLarge.copyWith(
                color: SeasonsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share anything on your mind',
              style: SeasonsTypography.bodyMedium.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      // Global version: +4dp extra spacing
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: _TypingIndicator(),
          );
        }
        final message = chatState.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20), // 16dp + 4dp extra for global
          child: _MessageBubble(message: message),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Image Preview
  // ──────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImagePaths.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < _selectedImagePaths.length) {
            final path = _selectedImagePaths[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path), width: 64, height: 64, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }
          return GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: SeasonsColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_photo_alternate, color: SeasonsColors.textTertiary),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Quick Questions — 3 chips
  // ──────────────────────────────────────────────

  Widget _buildQuickQuestions() {
    final questions = ['How are you feeling?', 'What should I eat?', 'I need to relax'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: questions.map((q) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _messageController.text = q;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SeasonsColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SeasonsColors.border),
                  ),
                  child: Text(
                    q,
                    style: SeasonsTypography.bodySmall.copyWith(
                      color: SeasonsColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Input Area — rounded 24, height 48
  // ──────────────────────────────────────────────

  Widget _buildInputArea(dynamic chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: SeasonsColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SeasonsColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: SeasonsTypography.bodyMedium.copyWith(
                          color: SeasonsColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening...' : 'Share your thoughts...',
                          hintStyle: SeasonsTypography.bodyMedium.copyWith(
                            color: SeasonsColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    // Voice button
                    if (_voiceInitialized)
                      GestureDetector(
                        onTap: _toggleVoice,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : SeasonsColors.textTertiary,
                            size: 22,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            GestureDetector(
              onTap: chatState.isLoading ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chatState.isLoading ? SeasonsColors.border : SeasonsColors.primary,
                  shape: BoxShape.circle,
                ),
                child: chatState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Message Bubble
// ═══════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    if (isUser) return _buildUserBubble(context);
    return _buildAIBubble(context);
  }

  /// User: right-aligned, light background, compact
  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SeasonsColors.primary.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: SeasonsTypography.bodyMedium.copyWith(
                  color: SeasonsColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: SeasonsTypography.captionLight.copyWith(
                  color: SeasonsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AI: left-aligned, white, larger, more spacious
  Widget _buildAIBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          // Global: +4dp extra padding
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: SeasonsColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: SeasonsShadows.small,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._parseContent(message.content),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: SeasonsTypography.captionLight.copyWith(
                  color: SeasonsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<Widget> _parseContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    final textLines = <String>[];

    for (final line in lines) {
      if (line.trimLeft().startsWith('🌿') || line.trimLeft().startsWith('💡')) {
        if (textLines.isNotEmpty) {
          widgets.add(Text(
            textLines.join('\n'),
            style: SeasonsTypography.bodyMedium.copyWith(
              color: SeasonsColors.textPrimary,
              height: 1.6,
            ),
          ));
          widgets.add(const SizedBox(height: 12));
          textLines.clear();
        }
        widgets.add(_SuggestionEmbed(
          icon: line.trimLeft().startsWith('🌿') ? '🌿' : '💡',
          title: line.replaceFirst(RegExp(r'^\s*[🌿💡]\s*'), ''),
        ));
        widgets.add(const SizedBox(height: 4));
      } else {
        textLines.add(line);
      }
    }

    if (textLines.isNotEmpty) {
      widgets.add(Text(
        textLines.join('\n'),
        style: SeasonsTypography.bodyMedium.copyWith(
          color: SeasonsColors.textPrimary,
          height: 1.6,
        ),
      ));
    }

    if (widgets.isEmpty) {
      widgets.add(Text(
        content,
        style: SeasonsTypography.bodyMedium.copyWith(
          color: SeasonsColors.textPrimary,
          height: 1.6,
        ),
      ));
    }

    return widgets;
  }
}

// ═══════════════════════════════════════════════
// Embedded Suggestion Card
// ═══════════════════════════════════════════════

class _SuggestionEmbed extends StatelessWidget {
  final String icon;
  final String title;

  const _SuggestionEmbed({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SeasonsColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SeasonsColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: SeasonsTypography.bodySmall.copyWith(
                color: SeasonsColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 12, color: SeasonsColors.textTertiary),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Typing Indicator
// ═══════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: SeasonsColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: SeasonsShadows.small,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final value = ((_controller.value + delay) % 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: SeasonsColors.textTertiary.withValues(alpha: 0.3 + value * 0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Guide Card Data
// ═══════════════════════════════════════════════

class _GuideCardData {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _GuideCardData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
