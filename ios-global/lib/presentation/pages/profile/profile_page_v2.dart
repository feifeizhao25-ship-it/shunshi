/// 个人中心页 — 参考UI _8
/// 积分/优惠券/收藏 + 功能入口 + 底部Slogan
library;

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../../data/network/session.dart';
import '../../../data/network/progress_api.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/locale_headers.dart';
import 'package:dio/dio.dart';

class ProfilePageV2 extends StatefulWidget {
  const ProfilePageV2({super.key});

  @override
  State<ProfilePageV2> createState() => _ProfilePageV2State();
}

class _ProfilePageV2State extends State<ProfilePageV2> {
  int _favoriteCount = 0;
  UserProgress? _progress;
  int? _couponCount;
  String _userName = 'SEASONS';

  final String _subscriptionTier = 'Free Plan';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resp = await ApiClient().get('/api/v1/favorites', queryParameters: {...userIdParam(), 'limit': 1});
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
    await _loadRewards();
  }

  /// Points and coupons come from the server (check-ins and badges add points; admins issue coupons).
  /// Nothing here is a placeholder: while loading or when signed out the tiles show an em dash.
  Future<void> _loadRewards() async {
    String? token;
    try {
      token = StorageManager.user.getToken();
    } catch (_) {}
    if (token == null || token.trim().isEmpty) return;
    final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 8), headers: LocaleHeaders.values));
    final p = await fetchUserProgress(dio, token: token, headers: LocaleHeaders.values);
    int? coupons;
    try {
      final r = await dio.get('/api/v1/coupon/my', options: Options(headers: {...LocaleHeaders.values, 'Authorization': 'Bearer $token'}));
      final d = r.data is Map && r.data['data'] is Map ? r.data['data'] as Map : const {};
      coupons = (d['total'] as num?)?.toInt();
    } catch (_) {}
    if (mounted) setState(() { _progress = p; _couponCount = coupons; });
  }

  Future<String> _getConstitution() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('constitution_type') ?? 'Balanced';
    } catch (_) {
      return 'Balanced';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : AppColors.background(context);

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
                    Text('SEASONS AI', style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: AppColors.primary(context),
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary(context)),
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
                      gradient: LinearGradient(
                        colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary(context).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Name + Verified
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_userName, style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      )),
                      const SizedBox(width: 6),
                      Icon(Icons.verified, size: 18, color: Color(0xFF144227)),
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
                                color: AppColors.primaryLight(context).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryLight(context).withOpacity(0.3)),
                              ),
                              child: Text('🌿 ${snap.data}', style: TextStyle(
                                fontSize: 12, color: AppColors.primary(context),
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
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStat('Points', _progress == null ? '—' : '${_progress!.points}'),
                    Container(width: 1, height: 32, color: AppColors.borderGhost(context)),
                    _buildStat('Coupons', _couponCount == null ? '—' : '$_couponCount'),
                    Container(width: 1, height: 32, color: AppColors.borderGhost(context)),
                    _buildStat('Favourites', '$_favoriteCount'),
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
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  _buildMenuTile(Icons.family_restroom, 'Family wellness', () => context.push('/family')),
                  _buildDivider(),
                  _buildMenuTile(Icons.military_tech, 'My achievement badges', () => context.push('/achievement')),
                  _buildDivider(),
                  _buildMenuTile(Icons.health_and_safety, 'Constitution report', () => context.push('/constitution-report')),
                  _buildDivider(),
                  _buildMenuTile(Icons.auto_awesome, 'Wellness diary', () => context.push('/diary')),
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
                  gradient: LinearGradient(
                    colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite friends, earn premium', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: AppColors.surface(context),
                    )),
                    const SizedBox(height: 4),
                    Text('Walk together and share the time to nourish yourselves', style: TextStyle(
                      fontSize: 13, color: Colors.white70,
                    )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Invite now', style: TextStyle(
                        fontSize: 13, color: AppColors.surface(context), fontWeight: FontWeight.w500,
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
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(children: [
                  _buildMenuTile(Icons.park, 'Manage subscription', () => context.push('/subscription')),
                  _buildDivider(),
                  _buildMenuTile(Icons.favorite_border, 'My favourites', () => context.push('/favorites')),
                  _buildDivider(),
                  _buildMenuTile(Icons.emoji_events_outlined, 'Wellness achievements', () => context.push('/achievement')),
                  _buildDivider(),
                  _buildMenuTile(Icons.settings, 'Settings', () => context.push('/settings')),
                  _buildDivider(),
                  _buildMenuTile(Icons.info_outline, 'About SEASONS', () => context.push('/about')),
                  _buildDivider(),
                  _buildMenuTile(Icons.headset_mic, 'Feedback', () => context.push('/feedback')),
                ]),
              ),
            ),
          ),

          // Slogan
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: Text('Live in rhythm with the seasons', style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 14, color: AppColors.textTertiary(context),
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
          color: AppColors.textPrimary(context),
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: 12, color: AppColors.textTertiary(context),
        )),
      ]),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary(context), size: 22),
      title: Text(title, style: TextStyle(
        fontSize: 15, color: AppColors.textPrimary(context),
      )),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.borderGhost(context)),
    );
  }
}
