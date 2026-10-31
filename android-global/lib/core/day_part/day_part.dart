/// Time-of-day wellness content for the international apps.
///
/// Replaces the traditional Chinese two-hour (shichen) clock that used to head the home screen
/// ("Shen · Bladder Meridian Active"): international users get plain parts of the day with
/// everyday wellness suggestions. Purely local, no network, no medical claims.
library;

import 'package:flutter/material.dart';

class BentoAction {
  final IconData icon;
  final String title;
  final String description;
  const BentoAction({required this.icon, required this.title, required this.description});
}

class DayPartData {
  /// "Morning", "Afternoon", ...
  final String name;
  /// Start and end hour as "a-b" (24h clock; may wrap past midnight, e.g. "22-5").
  final String timeRange;
  /// Short theme shown next to the name, e.g. "Focus time".
  final String focus;
  final String principle;
  final String principleShort;
  final String wellnessPrinciple;
  final String aiQuote;
  final IconData icon;
  final List<BentoAction> actions;

  const DayPartData({
    required this.name,
    required this.timeRange,
    required this.focus,
    required this.principle,
    required this.principleShort,
    required this.wellnessPrinciple,
    required this.aiQuote,
    required this.icon,
    required this.actions,
  });

  /// "15:00 - 18:00"
  String get timeDisplay {
    String two(String h) => h.padLeft(2, '0');
    final p = timeRange.split('-');
    return '${two(p[0])}:00 - ${two(p[1])}:00';
  }

  /// "Afternoon · Keep moving"
  String get headline => '$name · $focus';
}

DayPartData dayPartFor(DateTime now) {
  final hour = now.hour;
  for (final part in dayParts) {
    final p = part.timeRange.split('-');
    final start = int.parse(p[0]);
    final end = int.parse(p[1]);
    if (start <= end ? (hour >= start && hour < end) : (hour >= start || hour < end)) return part;
  }
  return dayParts.first;
}

DayPartData getCurrentDayPart() => dayPartFor(DateTime.now());

const dayParts = <DayPartData>[
  DayPartData(
    name: 'Night', timeRange: '22-5', focus: 'Rest and recover',
    principle: 'Sleep comes first', principleShort: 'Protect your sleep',
    wellnessPrinciple: 'Dim the lights, put screens away, let your body wind down',
    aiQuote: 'A steady bedtime does more for tomorrow than any late-night fix. If you are awake, keep the lights low and breathe slowly.',
    icon: Icons.dark_mode,
    actions: [
      BentoAction(icon: Icons.bedtime, title: 'Wind down', description: 'Dim the lights and put screens away 30 minutes before bed.'),
      BentoAction(icon: Icons.air, title: 'Slow breathing', description: 'Breathe in for 4 counts and out for 6 for a few minutes to settle.'),
    ],
  ),
  DayPartData(
    name: 'Early morning', timeRange: '5-8', focus: 'Gentle start',
    principle: 'Ease into the day', principleShort: 'Start gently',
    wellnessPrinciple: 'Water, light and light movement before the day gets busy',
    aiQuote: 'Open the curtains, drink a glass of water and stretch for a minute. A calm start sets the pace for the rest of the day.',
    icon: Icons.wb_twilight,
    actions: [
      BentoAction(icon: Icons.water_drop, title: 'Water first', description: 'A glass of water after waking helps you rehydrate.'),
      BentoAction(icon: Icons.self_improvement, title: 'Morning stretch', description: 'Two minutes of easy stretching loosens up a night of lying still.'),
    ],
  ),
  DayPartData(
    name: 'Morning', timeRange: '8-12', focus: 'Focus time',
    principle: 'Use your best hours', principleShort: 'Do the important thing first',
    wellnessPrinciple: 'Eat a proper breakfast, then protect an hour for your top task',
    aiQuote: 'Energy is usually highest in the morning for many people. Take the task that needs focus first, and stand up for a minute every hour.',
    icon: Icons.light_mode,
    actions: [
      BentoAction(icon: Icons.free_breakfast, title: 'Balanced breakfast', description: 'Protein, fibre and fruit keep energy steadier than sugar alone.'),
      BentoAction(icon: Icons.accessibility_new, title: 'Stand up hourly', description: 'Stand and stretch for a minute for every hour you sit.'),
    ],
  ),
  DayPartData(
    name: 'Midday', timeRange: '12-14', focus: 'Midday reset',
    principle: 'Pause and refuel', principleShort: 'Take a real break',
    wellnessPrinciple: 'Step away from the desk, eat without a screen, get some daylight',
    aiQuote: 'A proper lunch break, ideally with ten minutes outside, tends to make the afternoon easier than eating at your desk.',
    icon: Icons.restaurant,
    actions: [
      BentoAction(icon: Icons.restaurant_menu, title: 'Eat without a screen', description: 'Eating slowly makes it easier to notice when you are full.'),
      BentoAction(icon: Icons.directions_walk, title: 'Ten-minute walk', description: 'A short walk in daylight helps with afternoon energy.'),
    ],
  ),
  DayPartData(
    name: 'Afternoon', timeRange: '14-18', focus: 'Keep moving',
    principle: 'Keep the energy up', principleShort: 'Move a little',
    wellnessPrinciple: 'Water, a snack with protein, and a short stretch break',
    aiQuote: 'The afternoon dip is normal. A glass of water, a handful of nuts and a few minutes of movement usually help more than another coffee.',
    icon: Icons.directions_walk,
    actions: [
      BentoAction(icon: Icons.directions_run, title: 'Move a little', description: 'Walk a few flights of stairs or around the block to lift your energy.'),
      BentoAction(icon: Icons.local_drink, title: 'Hydrate', description: 'Keep water within reach and sip through the afternoon.'),
    ],
  ),
  DayPartData(
    name: 'Evening', timeRange: '18-22', focus: 'Wind down',
    principle: 'Slow the pace', principleShort: 'Wind down',
    wellnessPrinciple: 'Eat dinner a few hours before bed, then ease into quiet time',
    aiQuote: 'Try to finish dinner two to three hours before bed, and give yourself a screen-free half hour before sleep.',
    icon: Icons.nights_stay,
    actions: [
      BentoAction(icon: Icons.dinner_dining, title: 'Lighter dinner', description: 'Finish eating two to three hours before bed if you can.'),
      BentoAction(icon: Icons.menu_book, title: 'Screen-free time', description: 'Read, stretch or journal for a few minutes before sleep.'),
    ],
  ),
];
