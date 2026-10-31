// ignore_for_file: unused_field
/// 成就勋章页 — 参考UI _6
library;

import 'package:flutter/material.dart';
import '../../widgets/seasons_visual.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

class AchievementPageV2 extends StatefulWidget {
  const AchievementPageV2({super.key});

  @override
  State<AchievementPageV2> createState() => _AchievementPageV2State();
}

class _AchievementPageV2State extends State<AchievementPageV2> {
  int _chatCount = 0;
  int _diaryCount = 0;
  int _favoriteCount = 0;
  int _checkinStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
      _chatCount = prefs.getInt('chat_count') ?? 0;
      _diaryCount = prefs.getInt('diary_count') ?? 0;
      _favoriteCount = prefs.getInt('favorite_count') ?? 0;
      _checkinStreak = prefs.getInt('checkin_streak') ?? 0;
    });
    }
  }


  /// Every badge is earned from the counters this page already reads; nothing is pre-unlocked.
  List<(String, String, String, bool)> _badges() => [
        ('sg_badge_pioneer', 'First Steps', 'Chat, journal or save once', _chatCount + _diaryCount + _favoriteCount > 0),
        ('sg_badge_curious', 'Curious Mind', 'Start a chat', _chatCount >= 1),
        ('sg_badge_journal', 'Journal Keeper', 'Write a diary entry', _diaryCount >= 1),
        ('sg_badge_collector', 'Collector', 'Save a favorite', _favoriteCount >= 1),
        ('sg_badge_streak7', 'Week Streak', 'Check in 7 days in a row', _checkinStreak >= 7),
        ('sg_badge_streak30', 'Moon Cycle', 'Check in 30 days in a row', _checkinStreak >= 30),
        ('sg_badge_hundred', '100-Day Master', 'Check in 100 days in a row', _checkinStreak >= 100),
      ];

  Widget _badgeGrid(List<(String, String, String, bool)> items) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [for (final b in items) SgBadge(asset: 'assets/images/${b.$1}.webp', title: b.$2, subtitle: b.$3, unlocked: b.$4)],
      );

  List<Widget> _badgeSections() {
    final all = _badges();
    final earned = all.where((b) => b.$4).toList();
    final locked = all.where((b) => !b.$4).toList();
    final head = TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary);
    return [
      Text('Earned · ${earned.length} of ${all.length}', style: head),
      const SizedBox(height: 12),
      if (earned.isEmpty)
        const SgEmptyState(
          asset: 'assets/images/sg_empty.webp',
          title: 'No badges yet',
          message: 'Your first one is a single chat, diary entry or favorite away.',
        )
      else
        _badgeGrid(earned),
      if (locked.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Still to earn', style: head),
        const SizedBox(height: 12),
        _badgeGrid(locked),
      ],
      const SizedBox(height: 20),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Achievement Badges', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('Track every step of your wellness journey',
                style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            ),
            const SizedBox(height: 16),

            const SgHeroBanner(
              asset: 'assets/images/sg_hero_achieve.webp',
              title: 'Your wellness journey',
              subtitle: 'Badges unlock as you chat, journal and check in.',
            ),
            const SizedBox(height: 16),
            Row(children: [
              SgStatChip(icon: Icons.local_fire_department, label: 'Streak', value: '$_checkinStreak'),
              const SizedBox(width: 10),
              SgStatChip(icon: Icons.menu_book_outlined, label: 'Diary', value: '$_diaryCount'),
              const SizedBox(width: 10),
              SgStatChip(icon: Icons.chat_bubble_outline, label: 'Chats', value: '$_chatCount'),
              const SizedBox(width: 10),
              SgStatChip(icon: Icons.favorite_border, label: 'Saved', value: '$_favoriteCount'),
            ]),
            const SizedBox(height: 22),
            ..._badgeSections(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

}
