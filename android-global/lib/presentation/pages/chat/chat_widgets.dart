import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';
import 'chat_models.dart';
import '../../../core/theme/app_localizations.dart';

/// AI Messages气泡
class AIBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onFeedback;
  const AIBubble({super.key, required this.message, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: const BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🌱', style: TextStyle(fontSize: 18)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
          child: Text(message.text, style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context), height: 1.6))),
        if (message.cards != null) ...message.cards!.map((c) => Padding(padding: const EdgeInsets.only(top: 10), child: _SuggestionCardWidget(card: c))),
        if (message.sources != null && message.sources!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 10), child: _SourcesWrap(sources: message.sources!)),
        const SizedBox(height: 4),
        Row(children: [
          Text(message.time, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 11, color: ShunShiColors.textTertiary)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).t('chat_now_broadcasting')), duration: Duration(seconds: 2))); }, child: Icon(Icons.volume_up, size: 16, color: ShunShiColors.textTertiary)),
          const SizedBox(width: 8),
          if (onFeedback != null) GestureDetector(onTap: onFeedback, child: Icon(Icons.thumb_up_outlined, size: 16, color: ShunShiColors.textTertiary)),
        ]),
      ])),
    ]));
  }
}

/// 用户Messages气泡
class UserBubble extends StatelessWidget {
  final ChatMessage message;
  const UserBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(ShunShiRadius.lg)),
          child: Text(message.text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5))),
        const SizedBox(height: 4),
        Text(message.time, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 11, color: ShunShiColors.textTertiary)),
      ])),
    ]));
  }
}

/// 打字指示器
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: const BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle), child: const Center(child: Text('🌱', style: TextStyle(fontSize: 18)))),
      const SizedBox(width: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i > 0 ? 4 : 0), child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primary.withValues(alpha: 0.4))))))),
    ]));
  }
}

/// 骨架屏Messages
class SkeletonMessage extends StatelessWidget {
  final bool isAI;
  const SkeletonMessage({super.key, required this.isAI});

  @override
  Widget build(BuildContext context) {
    if (isAI) {
      return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.3), shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 60, decoration: BoxDecoration(color: ShunShiColors.borderGhost.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)))),
      ]));
    }
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(width: 200, height: 40, decoration: BoxDecoration(color: ShunShiColors.borderGhost.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12))),
    ]));
  }
}

/// UpgradeNotice条
class UpgradeNudge extends StatelessWidget {
  final VoidCallback onTap;
  const UpgradeNudge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [ShunShiColors.gold.withValues(alpha: 0.08), ShunShiColors.primary.withValues(alpha: 0.06)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.gold.withValues(alpha: 0.2))),
      child: Row(children: [
        Icon(Icons.auto_awesome, size: 18, color: ShunShiColors.gold),
        const SizedBox(width: 10),
        Expanded(child: Text('Continue deep conversations — unlock with one tap in the Nourish Heart edition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ShunShiColors.gold, fontFamily: ShunShiTypography.sansFamily))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: ShunShiColors.gold, borderRadius: BorderRadius.circular(10)), child: Text(AppLocalizations.of(context).t('chat_unlock'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
    ));
  }
}

class _SuggestionCardWidget extends StatelessWidget {
  final SuggestionCard card;
  const _SuggestionCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final tappable = ['diet', 'tea', 'recipe', 'herb', 'meridian', 'exercise', 'acupoint'].contains(card.type);
    return GestureDetector(
      onTap: tappable ? () => context.push('/diet-recommend', extra: {'constitutionType': null}) : null,
      child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(card.icon ?? Icons.auto_awesome, size: 16, color: ShunShiColors.primary), const SizedBox(width: 8), Expanded(child: Text(card.title, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary))), if (tappable) Icon(Icons.chevron_right, size: 16, color: ShunShiColors.primary)]),
        const SizedBox(height: 6),
        Text(card.subtitle, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
      ]),
    ));
  }
}

class _SourcesWrap extends StatelessWidget {
  final List<String> sources;
  const _SourcesWrap({required this.sources});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 6, children: sources.map((s) => GestureDetector(
      onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reference: $s'), duration: const Duration(seconds: 2))); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.15))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('📚', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(s, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 11, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
        ]),
      ),
    )).toList());
  }
}
