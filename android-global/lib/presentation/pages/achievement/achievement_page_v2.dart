// ignore_for_file: unused_field
/// 成就勋章页 — 参考UI _6
library;

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import '../../widgets/seasons_visual.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/locale_headers.dart';
import '../../../data/network/progress_api.dart';
import '../../../data/network/session.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

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

  UserProgress? _progress;
  bool _loaded = false;

  /// 数字全部来自服务端（打卡 / 日记 / 收藏 / 聊天写入接口留下的记录），不再读本地从来没人写过的计数。
  Future<void> _loadStats() async {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 8), headers: LocaleHeaders.values));
    final token = await ensureSessionToken(dio);
    final p = token == null ? null : await fetchUserProgress(dio, token: token, headers: LocaleHeaders.values);
    if (!mounted) return;
    setState(() {
      _progress = p;
      _loaded = true;
      _chatCount = p?.chatCount ?? 0;
      _diaryCount = p?.journalCount ?? 0;
      _favoriteCount = p?.favoriteCount ?? 0;
      _checkinStreak = p?.streakDays ?? 0;
    });
  }

  Widget _levelCard() {
    final p = _progress;
    if (!_loaded) return const SizedBox(height: 4, child: LinearProgressIndicator());
    if (p == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Text("Couldn't load your progress. Check your connection and try again.", style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)))),
          TextButton(onPressed: () { setState(() => _loaded = false); _loadStats(); }, child: const Text('Retry')),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Level ${p.level} · ${p.levelName}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          const Spacer(),
          Text('${p.points} points', style: TextStyle(fontSize: 14, color: AppColors.primary(context), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: p.levelProgress, minHeight: 6, backgroundColor: AppColors.surfaceContainerLow(context), color: AppColors.primary(context)),
        ),
        const SizedBox(height: 6),
        Text(
          p.nextLevelName == null ? 'Top level reached' : '${p.pointsToNextLevel} points to ${p.nextLevelName}',
          style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary(context)),
        ),
        const SizedBox(height: 4),
        Text('${p.totalCheckinDays} check-in days · ${p.badgeCount} of ${p.badgeTotal} badges', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary(context))),
      ]),
    );
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
    final head = TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : AppColors.background(context),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).t('achievement_achievement_badges'), style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(AppLocalizations.of(context).t('achievement_track_every_step_of_your_wellness_journey'),
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary(context))),
            ),
            const SizedBox(height: 16),

            const SgHeroBanner(
              asset: 'assets/images/sg_hero_achieve.webp',
              title: 'Your wellness journey',
              subtitle: 'Badges unlock as you chat, journal and check in.',
            ),
            const SizedBox(height: 16),
            _levelCard(),
            const SizedBox(height: 12),
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
