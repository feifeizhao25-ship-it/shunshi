import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/safety/system_notice_messages.dart';
import '../../data/models/message.dart';
import '../../design_system/design_system.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/subscription_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final show = _controller.text.trim().isNotEmpty;
      if (show != _showSendButton) setState(() => _showSendButton = show);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _showSendButton = false);
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);
    final userAsync = ref.watch(userContextProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final isPremium = subAsync.value?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '顺时',
        actions: [
          if (!isPremium)
            TextButton(
              onPressed: () => context.push('/subscribe'),
              child: const AppText.labelMedium(
                '连续照护',
                color: AppColors.primary,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.favorite_rounded, size: 14, color: AppColors.secondary),
                  SizedBox(width: AppSpacing.xs),
                  AppText.labelSmall('照护已开启', color: AppColors.secondary),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // SafeMode Banner
          chatAsync.when(
            data: (state) {
              if (!state.safeMode.isActive) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: AppNoticeCard.safety(
                  message: state.safeMode.noticeMessage ??
                      SystemNoticeMessages.safeModeBanner,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Messages
          Expanded(
            child: chatAsync.when(
              data: (state) {
                if (state.messages.isEmpty) {
                  return _buildEmpty();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: state.messages.length,
                  itemBuilder: (ctx, i) =>
                      _buildMessage(state.messages[i], userAsync.value?.userId ?? ''),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildError(),
            ),
          ),

          // Input Bar
          _buildInputBar(chatAsync.value?.isSending ?? false,
              chatAsync.value?.safeMode.isActive ?? false),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: AppColors.divider),
            const SizedBox(height: AppSpacing.lg),
            const AppText.bodyMedium(
              SystemNoticeMessages.emptyChatHistory,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppText.bodyMedium(SystemNoticeMessages.networkError),
            const SizedBox(height: AppSpacing.lg),
            AppButton.outline(
              label: '重试',
              onPressed: () => ref.invalidate(chatProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message msg, String userId) {
    final isUser = msg.sender == MessageSender.user;

    if (msg.type == MessageType.system || msg.isSafetyFlagged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: AppNoticeCard.safety(message: msg.text),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
        left: isUser ? AppSpacing.xxxl : 0,
        right: isUser ? 0 : AppSpacing.xxxl,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                ),
                boxShadow: isUser ? [] : AppShadows.soft,
              ),
              child: AppText.bodyLarge(
                msg.text,
                color: isUser ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            // Cards
            if (msg.cards != null && msg.cards!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...msg.cards!.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: AppCard.outlined(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books_outlined,
                            size: 18, color: AppColors.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppText.titleMedium(
                            card.title ?? card.type,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isSending, bool isSafeMode) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: isSafeMode ? '随时可以说…' : '有什么想聊的？',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.lgAll,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSending
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _showSendButton
                    ? IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                        color: AppColors.primary,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                        ),
                      )
                    : const SizedBox(width: 44),
          ),
        ],
      ),
    );
  }
}
