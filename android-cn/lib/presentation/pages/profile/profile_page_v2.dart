/// 个人中心页 — 参考UI _8
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
  String _userName = '\u987a\u65f6\u5c0f\u53cb';

  final String _subscriptionTier = '\u514d\u8d39\u7528\u6237';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resp = await ApiClient().get('/api/v1/favorites', queryParameters: {'user_id': 'guest', 'limit': 1});
      if (resp.data?['success'] == true) {
        final total = resp.data['data']?['total'] ?? 0;
        if (mounted) setState(() => _favoriteCount = total);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      if (name != null && mounted) setState(() => _userName = name);
    } catch (_) {}
  }

  Future<String> _getConstitution() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('constitution_type') ?? '平和质';
    } catch (_) {
      return '平和质';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text('ShunShi AI', style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: ShunShiColors.primary,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20, color: ShunShiColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar + Name + Badge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: ShunShiColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Name + Verified
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_userName, style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: ShunShiColors.textPrimary,
                      )),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 18, color: Color(0xFF144227)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 体质标签
                  FutureBuilder<String>(
                    future: _getConstitution(),
                    builder: (context, snap) => snap.hasData && snap.data!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: ShunShiColors.primaryLight.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ShunShiColors.primaryLight.withOpacity(0.3)),
                              ),
                              child: Text('🌿 ${snap.data}', style: TextStyle(
                                fontSize: 12, color: ShunShiColors.primary,
                                fontWeight: FontWeight.w500,
                              )),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // SVIP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_subscriptionTier, style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                    )),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row (积分/优惠券/收藏)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStat('积分', '2560'),
                    Container(width: 1, height: 32, color: ShunShiColors.borderGhost),
                    _buildStat('优惠券', '3 张'),
                    Container(width: 1, height: 32, color: ShunShiColors.borderGhost),
                    _buildStat('收藏', '$_favoriteCount'),
                  ],
                ),
              ),
            ),
          ),

          // 功能入口
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  _buildMenuTile(Icons.family_restroom, '家庭养生管理', () => context.push('/family')),
                  _buildDivider(),
                  _buildMenuTile(Icons.military_tech, '我的成就勋章', () => context.push('/achievement')),
                  _buildDivider(),
                  _buildMenuTile(Icons.health_and_safety, '体质报告', () => context.push('/constitution-report')),
                  _buildDivider(),
                  _buildMenuTile(Icons.auto_awesome, '养生日记', () => context.push('/diary')),
                ]),
              ),
            ),
          ),

          // 邀请好友卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('邀请好友领会员', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: ShunShiColors.surface,
                    )),
                    const SizedBox(height: 4),
                    Text('与友偕行，共享颐养时光', style: TextStyle(
                      fontSize: 13, color: Colors.white70,
                    )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('立即邀请', style: TextStyle(
                        fontSize: 13, color: ShunShiColors.surface, fontWeight: FontWeight.w500,
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 设置/客服
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  _buildMenuTile(Icons.park, '订阅管理', () => context.push('/subscription')),
                  _buildDivider(),
                  _buildMenuTile(Icons.favorite_border, '我的收藏', () => context.push('/favorites')),
                  _buildDivider(),
                  _buildMenuTile(Icons.emoji_events_outlined, '养生成就', () => context.push('/achievement')),
                  _buildDivider(),
                  _buildMenuTile(Icons.settings, '设置', () => context.push('/settings')),
                  _buildDivider(),
                  _buildMenuTile(Icons.info_outline, '关于顺时', () => context.push('/about')),
                  _buildDivider(),
                  _buildMenuTile(Icons.headset_mic, '意见反馈', () => context.push('/feedback')),
                ]),
              ),
            ),
          ),

          // Slogan
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: Text('顺应天时，颐养身心', style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 14, color: ShunShiColors.textTertiary,
                  fontStyle: FontStyle.italic,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold,
          color: ShunShiColors.textPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: 12, color: ShunShiColors.textTertiary,
        )),
      ]),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: ShunShiColors.primary, size: 22),
      title: Text(title, style: TextStyle(
        fontSize: 15, color: ShunShiColors.textPrimary,
      )),
      trailing: const Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: ShunShiColors.borderGhost),
    );
  }
}
