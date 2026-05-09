import 'package:flutter/material.dart';
import '../solar_term_detail_page.dart';
import '../../../../core/theme/shunshi_colors.dart';
import '../../../../core/theme/shunshi_text_styles.dart';
import 'solar_term_data.dart';
import '../../../../core/theme/app_localizations.dart';

class SolarTermTimeline extends StatelessWidget {
  final List<SolarTermInfo> allTerms;
  final int currentIndex;
  const SolarTermTimeline({super.key, required this.allTerms, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final seasons = <MapEntry<String, List<SolarTermInfo>>>[
      const MapEntry('Spring', []),
      const MapEntry('Summer', []),
      const MapEntry('Autumn', []),
      const MapEntry('Winter', []),
    ];
    for (final term in allTerms) {
      final idx = ['spring', 'summer', 'autumn', 'winter'].indexOf(term.season);
      if (idx >= 0 && idx < seasons.length) {
        seasons[idx] = MapEntry(seasons[idx].key, [...seasons[idx].value, term]);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).t('solar_24_solar_terms'), style: ShunshiTextStyles.heading),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: seasons.map((season) => SeasonRow(
                seasonLabel: season.key,
                terms: season.value,
                currentIndex: currentIndex,
                allTerms: allTerms,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SeasonRow extends StatelessWidget {
  final String seasonLabel;
  final List<SolarTermInfo> terms;
  final int currentIndex;
  final List<SolarTermInfo> allTerms;
  const SeasonRow({super.key, required this.seasonLabel, required this.terms, required this.currentIndex, required this.allTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(seasonLabel, style: ShunshiTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: ShunshiColors.primary)),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: terms.asMap().entries.expand((entry) {
                final index = entry.key;
                final term = entry.value;
                final globalIndex = allTerms.indexOf(term);
                final isCurrent = globalIndex == currentIndex;
                final isPast = globalIndex < currentIndex;
                final dotColor = isCurrent ? ShunshiColors.primary : isPast ? ShunshiColors.textHint : ShunshiColors.primaryLight;
                final textColor = isCurrent ? ShunshiColors.primary : isPast ? ShunshiColors.textHint : ShunshiColors.textSecondary;

                return <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SolarTermDetailPage(termName: term.name, season: term.season),
                    )),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isCurrent ? 10 : 0, vertical: isCurrent ? 6 : 0),
                      decoration: isCurrent ? BoxDecoration(color: ShunshiColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)) : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isCurrent ? 14 : 10, height: isCurrent ? 14 : 10,
                            decoration: BoxDecoration(
                              color: dotColor, shape: BoxShape.circle,
                              border: isCurrent ? Border.all(color: ShunshiColors.primary, width: 3) : null,
                              boxShadow: isCurrent ? [BoxShadow(color: ShunshiColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(width: 48, child: Text(term.name, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: isCurrent ? 13 : 12, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400, color: textColor))),
                        ],
                      ),
                    ),
                  ),
                  if (index < terms.length - 1)
                    Container(width: 24, height: 2, margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: isPast ? ShunshiColors.divider : ShunshiColors.primaryLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1))),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
