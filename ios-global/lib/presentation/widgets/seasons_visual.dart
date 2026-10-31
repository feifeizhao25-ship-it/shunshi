/// Image-led building blocks for the SEASONS international edition.
library;

import 'package:flutter/material.dart';

const _kGreen = Color(0xFF144227);
const _kGold = Color(0xFFE4C285);
const _kTextDim = Color(0xFF5E6B62);

Widget _sgImg(String asset, {double? w, double? h, BoxFit fit = BoxFit.cover}) => Image.asset(
      asset,
      width: w,
      height: h,
      fit: fit,
      errorBuilder: (_, _, _) => Container(width: w, height: h, color: const Color(0xFFE8E4D8)),
    );

/// Northern-hemisphere season for a date string like "2026-10-31" (falls back to today).
String sgSeasonFor(String? date) {
  DateTime d;
  try {
    d = DateTime.parse((date ?? '').trim());
  } catch (_) {
    d = DateTime.now();
  }
  switch (d.month) {
    case 3:
    case 4:
    case 5:
      return 'spring';
    case 6:
    case 7:
    case 8:
      return 'summer';
    case 9:
    case 10:
    case 11:
      return 'autumn';
    default:
      return 'winter';
  }
}

String sgSeasonLabel(String season) => '${season[0].toUpperCase()}${season.substring(1)}';

/// Rounded photo with a dark gradient and title/subtitle laid over it.
class SgHeroBanner extends StatelessWidget {
  const SgHeroBanner({super.key, required this.asset, required this.title, this.subtitle, this.height = 168});
  final String asset;
  final String title;
  final String? subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          _sgImg(asset),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xCC10241A)],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class SgBadge extends StatelessWidget {
  const SgBadge({super.key, required this.asset, required this.title, required this.subtitle, required this.unlocked});
  final String asset;
  final String title;
  final String subtitle;
  final bool unlocked;

  static const _gray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final img = ClipOval(child: _sgImg(asset, w: 84, h: 84));
    return Semantics(
      label: '$title, ${unlocked ? 'earned' : 'not yet earned'}. $subtitle',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : const Color(0xFFF1EEE4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: unlocked ? _kGold : const Color(0xFFDAD5C6)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          unlocked
              ? img
              : Opacity(opacity: 0.55, child: ColorFiltered(colorFilter: _gray, child: img)),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: unlocked ? _kGreen : _kTextDim)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.35, color: _kTextDim)),
        ]),
      ),
    );
  }
}

class SgEmptyState extends StatelessWidget {
  const SgEmptyState({super.key, required this.asset, required this.title, required this.message});
  final String asset;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: BorderRadius.circular(18), child: _sgImg(asset, w: 240, h: 150)),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kGreen)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.5, color: _kTextDim)),
      ]),
    );
  }
}

class SgStatChip extends StatelessWidget {
  const SgStatChip({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6E1D2))),
        child: Column(children: [
          Icon(icon, size: 20, color: _kGreen),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kGreen)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 12, color: _kTextDim))),
        ]),
      ),
    );
  }
}

/// One bar per entry, scaled 1..5 (the mood scale the API returns).
class SgMoodBars extends StatelessWidget {
  const SgMoodBars({super.key, required this.entries});
  final List<(String, int)> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final e in entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.$2}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
                const SizedBox(height: 2),
                Container(
                  height: 14.0 + 16.0 * e.$2.clamp(1, 5),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.25 + 0.15 * e.$2.clamp(1, 5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.$1, style: const TextStyle(fontSize: 11, color: _kTextDim)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class SgThumb extends StatelessWidget {
  const SgThumb({super.key, required this.asset, this.size = 52});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(12), child: _sgImg(asset, w: size, h: size));
}

/// Existing wellness photos, picked by section kind and a stable hash of the title.
String sgWellnessThumb(String kind, String title) {
  const foods = ['food_lotus_soup', 'food_red_bean_porridge', 'food_yam_porridge', 'food_spring_salad', 'food_winter_stew'];
  const moves = ['exercise_yoga_nature', 'exercise_morning_stretch', 'exercise_walking', 'exercise_taichi'];
  const teas = ['tea_chamomile', 'tea_green_tea', 'tea_goji_chrysanthemum', 'tea_rose', 'tea_longan'];
  final list = kind == 'exercise' ? moves : (kind == 'tea' ? teas : foods);
  var h = 0;
  for (final c in title.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 'assets/images/wellness/${list[h % list.length]}.jpg';
}

IconData sgIconForEmoji(String e) {
  switch (e) {
    case '❌':
      return Icons.block;
    case '✅':
      return Icons.check_circle_outline;
    case '🏥':
      return Icons.local_hospital_outlined;
    case '💊':
      return Icons.medication_outlined;
    case '🩺':
      return Icons.monitor_heart_outlined;
    case '📊':
      return Icons.bar_chart_rounded;
    case '😰':
      return Icons.sentiment_dissatisfied_outlined;
    case '🍃':
      return Icons.eco_outlined;
    case '🌱':
      return Icons.spa_outlined;
    case '💬':
      return Icons.chat_bubble_outline;
    case '😴':
      return Icons.bedtime_outlined;
    case '🍵':
      return Icons.emoji_food_beverage_outlined;
    case '⚠️':
      return Icons.warning_amber_rounded;
    default:
      return Icons.circle_outlined;
  }
}

class SgIconBadge extends StatelessWidget {
  const SgIconBadge({super.key, required this.emoji, required this.color, this.size = 44});
  final String emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: Icon(sgIconForEmoji(emoji), size: size * 0.52, color: color),
      );
}
