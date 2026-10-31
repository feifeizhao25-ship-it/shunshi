/// The chat's opening card. The Chinese solar-term descriptions are written for the northern hemisphere
/// ("Late autumn. Keep warm..."), so a southern user gets their own season instead of the term text.
library;

import '../utils/hemisphere_service.dart';

class OpeningGreeting {
  const OpeningGreeting({required this.text, required this.cardTitle, required this.cardSubtitle});
  final String text;
  final String cardTitle;
  final String cardSubtitle;
}

const _seasonAdvice = <SeasonType, String>{
  SeasonType.spring: 'Days are lengthening. Get outdoor light, ease back into regular movement and favour lighter meals.',
  SeasonType.summer: 'Long, warm days. Hydrate well, rest in the heat of midday and keep a steady sleep routine.',
  SeasonType.autumn: 'Evenings cool down. Keep warm, move gently and keep sleep and meals regular.',
  SeasonType.winter: 'Short, cold days. Prioritise rest, daylight when you can and warm, nourishing meals.',
};

OpeningGreeting openingGreeting({
  required String termName,
  required String termDesc,
  required Hemisphere hemisphere,
  DateTime? now,
}) {
  if (hemisphere == Hemisphere.north) {
    return OpeningGreeting(
      text: 'It\'s $termName, and the season is shifting. How have you been feeling lately, body and mind?',
      cardTitle: 'Now: $termName',
      cardSubtitle: termDesc,
    );
  }
  final season = HemisphereService.getCurrentSeason(hemisphere: hemisphere, date: now);
  final name = HemisphereService.getSeasonName(season);
  return OpeningGreeting(
    text: 'It\'s ${name.toLowerCase()} where you are, and the season is shifting. How have you been feeling lately, body and mind?',
    cardTitle: 'Now: $name · southern hemisphere',
    cardSubtitle: _seasonAdvice[season]!,
  );
}

/// "Frost Descent · Late Autumn" for the north (calendar table); the local season and its stage for the south
/// ("Mid Spring · southern hemisphere"), because the solar-term name belongs to the northern calendar.
String homeSeasonPill({
  required String termName,
  required String northSeasonLabel,
  required Hemisphere hemisphere,
  DateTime? now,
}) {
  if (hemisphere == Hemisphere.north) return '$termName \u00b7 $northSeasonLabel';
  final t = now ?? DateTime.now();
  final season = HemisphereService.getCurrentSeason(hemisphere: hemisphere, date: t);
  final month = t.month;
  // Position of the month inside its meteorological season: first month early, second mid, third late.
  final first = switch (season) {
    SeasonType.spring => 9,
    SeasonType.summer => 12,
    SeasonType.autumn => 3,
    SeasonType.winter => 6,
  };
  final index = (month - first + 12) % 12;
  final stage = const ['Early', 'Mid', 'Late'][index.clamp(0, 2)];
  return '$stage ${HemisphereService.getSeasonName(season)} \u00b7 southern hemisphere';
}
