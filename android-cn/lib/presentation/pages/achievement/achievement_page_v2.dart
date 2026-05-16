// ignore_for_file: unused_field
/// 成就勋章页 — 参考UI _6
/// 从 SharedPreferences 读取用户数据生成成就进度
library;

import 'package:flutter/material.dart';
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
  int _meditationCount = 0;
  int _points = 0;

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
        _meditationCount = prefs.getInt('meditation_count') ?? 0;
        _points = _chatCount * 10 + _diaryCount * 20 + _checkinStreak * 5 + _meditationCount * 15;
      });
    }
  }

  int get _level {
    if (_points >= 3000) return 5;
    if (_points >= 2000) return 4;
    if (_points >= 1000) return 3;
    if (_points >= 300) return 2;
    return 1;
  }

  String get _levelTitle {
    const titles = ['入门修行者', '初级养生者', '中级养生者', '高级养生者', '养生大师'];
    return titles[_level - 1];
  }

  String get _nextLevelTitle {
    if (_level >= 5) return '已满级';
    const titles = ['初级养生者', '中级养生者', '高级养生者', '养生大师', ''];
    return titles[_level - 1];
  }

  int get _nextLevelPoints {
    const thresholds = [300, 1000, 2000, 3000, 9999];
    return thresholds[_level - 1];
  }

  List<_Badge> get _badges => [
    _Badge(Icons.wb_sunny, '早起达人', '连续早起$_checkinStreak/10天', _checkinStreak >= 10, _checkinStreak / 10, ShunShiColors.primary),
    _Badge(Icons.eco, '节气使者', '顺时而养', _checkinStreak >= 3, _checkinStreak / 3, const Color(0xFF2D7A4A)),
    _Badge(Icons.storm, '养生先锋', '聊天$_chatCount/50次', _chatCount >= 50, _chatCount / 50, const Color(0xFF74593C)),
    _Badge(Icons.auto_stories, '日记达人', '日记$_diaryCount/30篇', _diaryCount >= 30, _diaryCount / 30, const Color(0xFF7c5cfc)),
    _Badge(Icons.self_improvement, '冥想行者', '冥想$_meditationCount/20次', _meditationCount >= 20, _meditationCount / 20, const Color(0xFF533afd)),
    _Badge(Icons.favorite, '收藏家', '收藏$_favoriteCount/10个', _favoriteCount >= 10, _favoriteCount / 10, Colors.pink),
    _Badge(Icons.history_edu, '百日功成', '打卡$_checkinStreak/100天', _checkinStreak >= 100, _checkinStreak / 100, Colors.orange),
    _Badge(Icons.family_restroom, '全家康泰', '亲友共修', false, 0, null),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final badges = _badges;
    final unlocked = badges.where((b) => b.unlocked).toList();
    final locked = badges.where((b) => !b.unlocked).toList();
    final progress = _nextLevelPoints > 0 ? _points / _nextLevelPoints : 1.0;
    final remaining = _nextLevelPoints - _points;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('成就勋章', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('记录您的每一次健康修行',
                style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            ),
            const SizedBox(height: 16),

            // Points & Level Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('$_points', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('积分', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('当前等级：$_levelTitle', style: TextStyle(fontSize: 14, color: Color(0xFFE4C285))),
                  if (_level < 5) ...[
                    const SizedBox(height: 4),
                    Text('下一级：$_nextLevelTitle', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        color: Color(0xFFE4C285), minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('距离升级还需 $remaining 积分', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              _statCard('聊天', _chatCount, Icons.chat),
              const SizedBox(width: 8),
              _statCard('日记', _diaryCount, Icons.auto_stories),
              const SizedBox(width: 8),
              _statCard('冥想', _meditationCount, Icons.self_improvement),
              const SizedBox(width: 8),
              _statCard('连续', _checkinStreak, Icons.local_fire_department),
            ]),
            const SizedBox(height: 20),

            // Unlocked badges
            Row(children: [
              Text('已获荣光', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
              const Spacer(),
              Text('${unlocked.length} / ${badges.length} 已解锁', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
            ]),
            const SizedBox(height: 12),

            if (unlocked.isNotEmpty) GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
              children: unlocked.map((b) => _buildBadgeCard(b)).toList(),
            ),

            if (locked.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(children: [
                Text('待登峰造极', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
              ]),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
                children: locked.map((b) => _buildBadgeCard(b)).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // AI tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ShunShiColors.primary.withOpacity(0.15)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.auto_awesome, color: ShunShiColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_getAITip(), style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getAITip() {
    if (_checkinStreak >= 7) return '连续打卡$_checkinStreak天，太棒了！距离"百日功成"还需${100 - _checkinStreak}天。';
    if (_chatCount < 10) return '再和顺时AI聊${10 - _chatCount}次，即可解锁更多养生建议。';
    if (_meditationCount < 5) return '试试冥想功能，再冥想${5 - _meditationCount}次就能获得"冥想行者"勋章。';
    return '坚持每天打卡、聊天、冥想，解锁更多成就勋章。';
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: ShunShiColors.primary),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
        ]),
      ),
    );
  }

  Widget _buildBadgeCard(_Badge badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.unlocked ? ShunShiColors.surface : ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: badge.unlocked && badge.color != null ? Border.all(color: badge.color!.withOpacity(0.3)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon, size: 32,
            color: badge.unlocked ? (badge.color ?? ShunShiColors.primary) : ShunShiColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(badge.title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: badge.unlocked ? ShunShiColors.textPrimary : ShunShiColors.textTertiary,
          )),
          const SizedBox(height: 2),
          Text(badge.desc, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          if (!badge.unlocked && badge.progress > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: badge.progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: ShunShiColors.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color ?? ShunShiColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge {
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;
  final double progress;
  final Color? color;
  const _Badge(this.icon, this.title, this.desc, this.unlocked, this.progress, this.color);
}
