/// Growth Milestones — 参考 growth_milestones
/// XP + badges + streak — 从 SharedPreferences 加载真实数据
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

class GrowthMilestonesV2 extends StatefulWidget {
  const GrowthMilestonesV2({super.key});

  @override
  State<GrowthMilestonesV2> createState() => _GrowthMilestonesV2State();
}

class _GrowthMilestonesV2State extends State<GrowthMilestonesV2> {
  int _checkinStreak = 0;
  int _chatCount = 0;
  int _diaryCount = 0;
  int _meditationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _checkinStreak = prefs.getInt('checkin_streak') ?? 0;
        _chatCount = prefs.getInt('chat_count') ?? 0;
        _diaryCount = prefs.getInt('diary_count') ?? 0;
        _meditationCount = prefs.getInt('meditation_count') ?? 0;
      });
    }
  }

  int get _points => _chatCount * 10 + _diaryCount * 20 + _checkinStreak * 5 + _meditationCount * 15;

  double get _seasonProgress {
    // Simple: 85 milestones in current season based on activity
    final total = 100;
    return (_checkinStreak + _chatCount + _diaryCount + _meditationCount) / total;
  }

  List<_Milestone> get _milestones => [
    _Milestone(Icons.local_florist, 'First Sprout', 'Ritual streak: 3 days', _checkinStreak >= 3, const Color(0xFF4CAF50)),
    _Milestone(Icons.chat, '对话达人', '与AI聊天: $_chatCount/10', _chatCount >= 10, const Color(0xFF7c5cfc)),
    _Milestone(Icons.auto_stories, 'Story Keeper', 'Write diaries: $_diaryCount/5', _diaryCount >= 5, Colors.orange),
    _Milestone(Icons.self_improvement, 'Mindful One', 'Meditate: $_meditationCount/10', _meditationCount >= 10, const Color(0xFF533afd)),
    _Milestone(Icons.forest, 'Deep Roots', 'Complete a seasonal cycle', _checkinStreak >= 30, null),
    _Milestone(Icons.wb_sunny, 'Solar Devotee', '30 morning rituals', _checkinStreak >= 30, null),
    _Milestone(Icons.water_drop, 'Rain Dancer', 'Practice in every weather', false, null),
    _Milestone(Icons.auto_awesome, 'Equinox Aligned', 'Balance all 4 pillars', false, null),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF533afd), size: 20),
                ),
                const Spacer(),
                Text('Digital Sanctuary', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
            ),
          )),

          // Title
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('你的成长之旅', style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 8),
              Text('每一步坚持都是种在健康花园里的一颗种子。',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
            ]),
          )),

          // Current Season Card
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('当前季节', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('春分调养', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text("你已连续早起 $_checkinStreak 天。内在的清晰正在绽放。",
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _seasonProgress.clamp(0.0, 1.0), backgroundColor: Colors.white24, color: Color(0xFFE4C285), minHeight: 6),
                ),
                const SizedBox(height: 4),
                Text('${(_seasonProgress * 100).toInt()}% TOWARDS HARVEST', style: TextStyle(fontSize: 11, color: Color(0xFFE4C285))),
              ]),
            ),
          )),

          // Stats
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              Expanded(child: _buildStatBox(Icons.local_fire_department, '$_checkinStreak', '天连续打卡')),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(Icons.chat, '$_chatCount', '次AI对话')),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(Icons.star, '$_points', '积分')),
            ]),
          )),

          // Milestones
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reflective Milestones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              Text('Gently nurtured achievements', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
              const SizedBox(height: 12),
              ..._milestones.map((m) => _buildMilestone(m)),
            ]),
          )),

          const SliverToBoxAlternate(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: Color(0xFF533afd), size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildMilestone(_Milestone m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: m.unlocked && m.color != null ? Border.all(color: m.color!.withOpacity(0.3)) : null,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: m.unlocked ? (m.color ?? Color(0xFF533afd)).withOpacity(0.1) : ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: m.unlocked
              ? Icon(Icons.check, color: m.color ?? Color(0xFF533afd), size: 20)
              : Icon(Icons.lock_outline, color: ShunShiColors.textTertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: m.unlocked ? ShunShiColors.textPrimary : ShunShiColors.textTertiary)),
            Text(m.desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          ])),
        ]),
      ),
    );
  }
}

class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}

class _Milestone {
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;
  final Color? color;
  const _Milestone(this.icon, this.title, this.desc, this.unlocked, this.color);
}
