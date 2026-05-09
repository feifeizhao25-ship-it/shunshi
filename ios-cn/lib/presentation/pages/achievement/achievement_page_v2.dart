// ignore_for_file: unused_field
/// 成就勋章页 — 参考UI _6
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('成就勋章', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 副标题
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('记录您的每一次健康修行',
                style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
            ),
            const SizedBox(height: 16),

            // 积分和等级
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('2560', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('积分', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('当前等级：入门修行者', style: TextStyle(fontSize: 14, color: Color(0xFFE4C285))),
                  const SizedBox(height: 4),
                  Text('下一级：中级养生者', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 2560 / 3000, backgroundColor: Colors.white24,
                      color: Color(0xFFE4C285), minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('距离升级还需 440 积分', style: TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 已获荣光
            Row(children: [
              Text('已获荣光', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
              const Spacer(),
              Text('3 / 8 已解锁', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
            ]),
            const SizedBox(height: 12),

            // Unlocked badges
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
              children: [
                _buildBadgeCard(Icons.wb_sunny, '早起达人', '10天 达成', true, ShunShiColors.primary),
                _buildBadgeCard(Icons.eco, '节气使者', '顺时而养', true, Color(0xFF2D7A4A)),
                _buildBadgeCard(Icons.storm, '养生先锋', '初窥门径', true, Color(0xFF74593C)),
              ],
            ),
            const SizedBox(height: 24),

            // 待登峰造极
            Row(children: [
              Text('待登峰造极', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
            ]),
            const SizedBox(height: 12),

            // Locked badges
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
              children: [
                _buildBadgeCard(Icons.history_edu, '百日功成', '进阶解锁', false, null),
                _buildBadgeCard(Icons.family_restroom, '全家康泰', '亲友共修', false, null),
                _buildBadgeCard(Icons.lock, '虚位以待', '', false, null),
                _buildBadgeCard(Icons.lock, '虚位以待', '', false, null),
                _buildBadgeCard(Icons.lock, '虚位以待', '', false, null),
              ],
            ),
            const SizedBox(height: 20),

            // AI 小贴士
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
                Expanded(child: Text('再坚持早起 3 天，即可获得"晨曦悟道"隐藏勋章。', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(IconData icon, String title, String subtitle, bool unlocked, Color? color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? ShunShiColors.surface : ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: unlocked && color != null ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32,
            color: unlocked ? (color ?? ShunShiColors.primary) : ShunShiColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: unlocked ? ShunShiColors.textPrimary : ShunShiColors.textTertiary,
          )),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}
