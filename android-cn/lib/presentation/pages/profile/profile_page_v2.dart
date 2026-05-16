/// 个人中心页 — 参考UI _8（升级版）
/// 积分/优惠券/收藏 + 功能入口 + 底部Slogan
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';

class ProfilePageV2 extends StatefulWidget {
  const ProfilePageV2({super.key});

  @override
  State<ProfilePageV2> createState() => _ProfilePageV2State();
}

class _ProfilePageV2State extends State<ProfilePageV2> {
  int _favoriteCount = 0;
  int _wellnessDays = 0;
  int _checkinCount = 0;
  String _userName = '顺时小朋友';
  int _checkinDays = 0;
  String _constitution = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load stats from API
    try {
      final results = await Future.wait([
        ApiClient().get('/api/v1/favorites', queryParameters: {'user_id': 'guest', 'limit': 1}),
        ApiClient().get('/api/v1/records/care/stats'),
      ]);
      // Favorites count
      final favResp = results[0];
      if (favResp.data?['success'] == true) {
        final total = favResp.data['data']?['total'] ?? 0;
        if (mounted) setState(() => _favoriteCount = total);
      }
      // Care stats
      final statsResp = results[1];
      if (statsResp.data is Map && statsResp.data['data'] is Map) {
        final d = statsResp.data['data'] as Map<String, dynamic>;
        if (mounted) setState(() {
          _wellnessDays = d['total_days'] as int? ?? 0;
          _checkinCount = d['total_checkins'] as int? ?? d['week_streak'] as int? ?? 0;
        });
      }
    } catch (_) {}
    // 2. Load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final days = prefs.getInt('checkin_days') ?? 0;
      final constitution = prefs.getString('constitution_type') ?? '';
      if (mounted) {
        setState(() {
          if (name != null) _userName = name;
          _checkinDays = days;
          _constitution = constitution;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final cardColor = isDark ? ShunShiColors.darkSurface : ShunShiColors.surface;
    final primaryColor = isDark ? ShunShiColors.darkPrimary : ShunShiColors.primary;
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textSecondary = isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;
    final textTertiary = isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text('ShunShi AI',
                        style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? ShunShiColors.darkSurfaceContainerLow
                              : ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_outlined,
                            size: 20, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 头像区域：大圆形 + 墨绿渐变光环 + 编辑角标 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  // 头像光环 + 编辑按钮
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        // 外圈光环
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                ShunShiColors.primary,
                                ShunShiColors.primaryLight,
                                ShunShiColors.apricot,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ShunShiColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          // 内圈头像
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? ShunShiColors.darkSurfaceContainerLowest
                                  : ShunShiColors.surfaceContainerLowest,
                            ),
                            child: Icon(Icons.person,
                                size: 44, color: primaryColor),
                          ),
                        ),
                        // 编辑角标
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => context.push('/profile/edit'),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ShunShiColors.primary,
                                border: Border.all(
                                  color: bg,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 名字 — 大号衬线体
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_userName,
                          style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          )),
                      const SizedBox(width: 6),
                      Icon(Icons.verified,
                          size: 18, color: primaryColor),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 体质标签（小胶囊）
                  if (_constitution.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: GestureDetector(
                        onTap: () => context.push('/constitution-report'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌿', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(_constitution,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 连续打卡天数
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: ShunShiColors.apricotLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text('连续打卡 $_checkinDays 天',
                            style: TextStyle(
                              fontSize: 11,
                              color: ShunShiColors.secondary,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 统计卡片：横向3格 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : ShunShiShadows.sm,
                ),
                child: Row(
                  children: [
                    _buildStat(context, '养生天数', '$_wellnessDays', isDark),
                    _buildStatDivider(isDark),
                    _buildStat(context, '打卡次数', '$_checkinCount', isDark),
                    _buildStatDivider(isDark),
                    _buildStat(context, '收藏数', '$_favoriteCount', isDark),
                  ],
                ),
              ),
            ),
          ),

          // ── 功能菜单组1：核心功能 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : ShunShiShadows.sm,
                ),
                child: Column(children: [
                  _buildMenuTile(context, Icons.favorite_border,
                      '我的收藏', const [Color(0xFFE57373), Color(0xFFFF8A80)],
                      () => context.push('/favorites')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.health_and_safety,
                      '体质报告', const [Color(0xFF144227), Color(0xFF3E7A55)],
                      () => context.push('/constitution-report')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.family_restroom,
                      '家人管理', const [Color(0xFF6B8FAD), Color(0xFF9BB8C9)],
                      () => context.push('/family')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.military_tech,
                      '成就徽章', const [Color(0xFFFFB74D), Color(0xFFFFD54F)],
                      () => context.push('/achievement')),
                ]),
              ),
            ),
          ),

          // ── 功能菜单组2：设置类 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : ShunShiShadows.sm,
                ),
                child: Column(children: [
                  _buildMenuTile(context, Icons.notifications_outlined,
                      '通知设置', const [Color(0xFF7986CB), Color(0xFF9FA8DA)],
                      () => context.push('/notifications')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.lock_outline,
                      '隐私设置', const [Color(0xFF4DB6AC), Color(0xFF80CBC4)],
                      () => context.push('/privacy')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.dark_mode_outlined,
                      '深色模式', const [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                      () => context.push('/theme-settings')),
                  _buildDivider(isDark),
                  _buildMenuTile(context, Icons.info_outline,
                      '关于', const [Color(0xFF90A4AE), Color(0xFFB0BEC5)],
                      () => context.push('/about')),
                ]),
              ),
            ),
          ),

          // ── 邀请好友卡片 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ShunShiColors.primary,
                      ShunShiColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('邀请好友领会员',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text('与友偕行，共享颐养时光',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('立即邀请',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 退出登录（红色）──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : ShunShiShadows.sm,
                ),
                child: ListTile(
                  leading: _buildGradientIcon(
                      const [Color(0xFFE57373), Color(0xFFEF5350)],
                      Icons.logout),
                  title: Text('退出登录',
                      style: TextStyle(
                        fontSize: 15,
                        color: ShunShiColors.error,
                        fontWeight: FontWeight.w500,
                      )),
                  trailing: Icon(Icons.chevron_right,
                      color: ShunShiColors.error.withValues(alpha: 0.5), size: 20),
                  onTap: () => context.go('/login'),
                ),
              ),
            ),
          ),

          // ── Slogan ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: Text('顺应天时，颐养身心',
                    style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 14,
                      color: textTertiary,
                      fontStyle: FontStyle.italic,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 统计项 — 数字大 + 标签小
  Widget _buildStat(BuildContext context, String label, String value, bool isDark) {
    final textPrimary = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final textTertiary = isDark ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: ShunShiTypography.serifFamily,
              color: textPrimary,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: textTertiary,
            )),
      ]),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost,
    );
  }

  /// 菜单项 — 左侧渐变圆形图标背景 + 白色图标
  Widget _buildMenuTile(BuildContext context, IconData icon, String title,
      List<Color> gradientColors, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    return ListTile(
      leading: _buildGradientIcon(gradientColors, icon),
      title: Text(title,
          style: TextStyle(
            fontSize: 15,
            color: textPrimary,
          )),
      trailing: Icon(Icons.chevron_right,
          color: isDark
              ? ShunShiColors.darkTextTertiary
              : ShunShiColors.textTertiary,
          size: 20),
      onTap: onTap,
    );
  }

  /// 渐变圆形图标
  Widget _buildGradientIcon(List<Color> colors, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost,
      ),
    );
  }
}
