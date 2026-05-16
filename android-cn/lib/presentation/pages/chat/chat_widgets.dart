import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';
import 'chat_models.dart';

// ── AI 头像：墨绿渐变 + eco 图标 ──

class _AIAvatar extends StatelessWidget {
  const _AIAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
        ),
      ),
      child: const Center(child: Icon(Icons.eco, size: 20, color: Colors.white)),
    );
  }
}

// ── AI 消息气泡 ──

class AIBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onFeedback;
  const AIBubble({super.key, required this.message, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest;
    final borderColor = isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AIAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? [] : ShunShiShadows.sm,
                  ),
                  child: Text(message.text,
                      style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                          height: 1.6)),
                ),
                if (message.cards != null)
                  ...message.cards!.map((c) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _SuggestionCardWidget(card: c))),
                if (message.sources != null && message.sources!.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _SourcesWrap(sources: message.sources!)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(message.time,
                        style: TextStyle(
                            fontFamily: ShunShiTypography.sansFamily,
                            fontSize: 11,
                            color: AppColors.textTertiary(context))),
                    const SizedBox(width: 8),
                    GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('正在播报...'),
                                  duration: Duration(seconds: 2)));
                        },
                        child: Icon(Icons.volume_up,
                            size: 16,
                            color: AppColors.textTertiary(context))),
                    const SizedBox(width: 8),
                    if (onFeedback != null)
                      GestureDetector(
                          onTap: onFeedback,
                          child: Icon(Icons.thumb_up_outlined,
                              size: 16,
                              color: AppColors.textTertiary(context))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 用户消息气泡：墨绿渐变 + 白字 + 差异化圆角 ──

class UserBubble extends StatelessWidget {
  final ChatMessage message;
  const UserBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        ShunShiColors.primary,
                        ShunShiColors.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(message.text,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.white, height: 1.5)),
                ),
                const SizedBox(height: 4),
                Text(message.time,
                    style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 11,
                        color: AppColors.textTertiary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 打字指示器：三个跳动的绿色圆点 ──

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isDark ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest;
    final borderColor = isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AIAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : ShunShiShadows.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Stagger each dot by 0.2 interval
                    final double t =
                        (_controller.value - i * 0.15).clamp(0.0, 1.0) % 1.0;
                    final double scale =
                        (sin(t * 2 * pi) + 1) / 2; // 0..1 bounce
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -scale * 4),
                        child: Opacity(
                          opacity: 0.4 + scale * 0.6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ShunShiColors.primary
                                  .withValues(alpha: 0.4 + scale * 0.6),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 骨架屏消息 ──

class SkeletonMessage extends StatelessWidget {
  final bool isAI;
  const SkeletonMessage({super.key, required this.isAI});

  @override
  Widget build(BuildContext context) {
    if (isAI) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color:
                            ShunShiColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                    child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                            color: ShunShiColors.borderGhost
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16)))),
              ]));
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                  color:
                      ShunShiColors.borderGhost.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12))),
        ]));
  }
}

// ── 升级提示条 ──

class UpgradeNudge extends StatelessWidget {
  final VoidCallback onTap;
  const UpgradeNudge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                ShunShiColors.gold.withValues(alpha: 0.08),
                ShunShiColors.primary.withValues(alpha: 0.06)
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: ShunShiColors.gold.withValues(alpha: 0.2))),
          child: Row(children: [
            Icon(Icons.auto_awesome, size: 18, color: ShunShiColors.gold),
            const SizedBox(width: 10),
            Expanded(
                child: Text('继续深度对话，养心版一键解锁',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ShunShiColors.gold,
                        fontFamily: ShunShiTypography.sansFamily))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: ShunShiColors.gold,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('解锁',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white))),
          ]),
        ));
  }
}

// ── 建议卡片 ──

class _SuggestionCardWidget extends StatelessWidget {
  final SuggestionCard card;
  const _SuggestionCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final tappable = ['diet', 'tea', 'recipe', 'herb', 'meridian', 'exercise', 'acupoint'].contains(card.type);
    return GestureDetector(
      onTap: tappable
          ? () => context.push('/diet-recommend',
              extra: {'constitutionType': null})
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: ShunShiColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: ShunShiColors.primary.withValues(alpha: 0.1))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(card.icon ?? Icons.auto_awesome,
                    size: 16, color: ShunShiColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(card.title,
                        style: TextStyle(
                            fontFamily: ShunShiTypography.sansFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ShunShiColors.primary))),
                if (tappable)
                  Icon(Icons.chevron_right,
                      size: 16, color: ShunShiColors.primary)
              ]),
              const SizedBox(height: 6),
              Text(card.subtitle,
                  style: TextStyle(
                      fontSize: 13,
                      color: ShunShiColors.textSecondary,
                      height: 1.5)),
            ]),
      ),
    );
  }
}

// ── 参考来源 ──

class _SourcesWrap extends StatelessWidget {
  final List<String> sources;
  const _SourcesWrap({required this.sources});

  @override
  Widget build(BuildContext context) {
    return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: sources
            .map((s) => GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('参考来源：$s'),
                        duration: const Duration(seconds: 2)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color:
                            ShunShiColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: ShunShiColors.primary
                                .withValues(alpha: 0.15))),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(s,
                              style: TextStyle(
                                  fontFamily: ShunShiTypography.sansFamily,
                                  fontSize: 11,
                                  color: ShunShiColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                ))
            .toList());
  }
}

// ── 快捷提问标签 ──

class QuickQuestionChips extends StatelessWidget {
  final void Function(String) onTap;
  const QuickQuestionChips({super.key, required this.onTap});

  static const _questions = [
    '今天吃什么好',
    '适合什么运动',
    '推荐养生茶饮',
    '换季怎么调理',
    '最近睡眠不好',
    '情绪低落怎么办',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark
        ? ShunShiColors.darkSurfaceContainerLowest
        : ShunShiColors.surfaceContainerLowest;
    final chipBorder =
        isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;
    final textColor = isDark
        ? ShunShiColors.darkTextSecondary
        : ShunShiColors.textSecondary;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => onTap(_questions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: chipBorder),
              ),
              child: Center(
                child: Text(
                  _questions[i],
                  style: TextStyle(
                    fontFamily: ShunShiTypography.sansFamily,
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 渐变发送按钮 ──

class GradientSendButton extends StatefulWidget {
  final VoidCallback onTap;
  const GradientSendButton({super.key, required this.onTap});

  @override
  State<GradientSendButton> createState() => _GradientSendButtonState();
}

class _GradientSendButtonState extends State<GradientSendButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ShunShiColors.primary, ShunShiColors.primaryContainer],
            ),
          ),
          child: const Icon(Icons.send, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
