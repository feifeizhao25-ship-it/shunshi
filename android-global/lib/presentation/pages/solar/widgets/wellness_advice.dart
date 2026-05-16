import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/shunshi_colors.dart';
import '../../../../core/theme/shunshi_spacing.dart';
import '../../../../core/theme/shunshi_text_styles.dart';
import 'solar_term_data.dart';
import '../../../../core/theme/app_localizations.dart';
import '../../../../core/network/api_singleton.dart';

class WellnessAdvice extends StatelessWidget {
  final SolarTermInfo term;
  const WellnessAdvice({super.key, required this.term});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).t('constitution_wellness_tips'), style: ShunshiTextStyles.heading),
          const SizedBox(height: 16),
          AdviceGroup(icon: '🍵', title: AppLocalizations.of(context).t('solar_diet_wellness'), items: term.diet, type: 'food_therapy'),
          const SizedBox(height: 16),
          AdviceGroup(icon: '💆', title: AppLocalizations.of(context).t('solar_acupressure'), items: term.acupoint, type: 'acupoint'),
          const SizedBox(height: 16),
          AdviceGroup(icon: '🏃', title: AppLocalizations.of(context).t('solar_exercisesuggestion'), items: term.exercise, type: 'exercise'),
          const SizedBox(height: 16),
          AdviceGroup(icon: '😊', title: AppLocalizations.of(context).t('solar_emotionswellness'), items: term.emotion, type: 'emotion'),
        ],
      ),
    );
  }
}

class AdviceGroup extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> items;
  final String type;
  const AdviceGroup({super.key, required this.icon, required this.title, required this.items, this.type = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        border: Border.all(color: ShunshiColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () { if (type.isNotEmpty) context.go('/wellness-category/$type'); },
            child: Row(children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title, style: ShunshiTextStyles.heading.copyWith(fontSize: 15)),
              if (type.isNotEmpty) ...[
                const Spacer(),
                Text(AppLocalizations.of(context).t('view_all'), style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.primary)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: ShunshiColors.primary),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => GestureDetector(
            onTap: () { if (type.isNotEmpty) context.go('/wellness-category/$type'); },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: ShunshiTextStyles.body.copyWith(fontSize: 14))),
                Icon(Icons.chevron_right, size: 14, color: ShunshiColors.textSecondary),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
