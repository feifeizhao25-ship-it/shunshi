/// 个人中心页
///
/// ─── 这一页原来显示的是假的用户资产 ───────────────────────────
///
/// 2026-09-14 真实浏览器验收（S-01）：**未登录**打开个人中心，
/// 看到「积分 2560」「优惠券 3 张」。查下来是第 182 / 184 行两个写死的
/// 字符串——这两个数与任何账号、任何接口都没有关系。
///
/// 一起查出来的还有四处同类问题：
///
///   · `_loadData()` 拿收藏数时 **`user_id` 写死成 `'guest'`**，
///     所以登录之后显示的也不是自己的收藏数；
///   · 名字旁边无条件渲染 `Icons.verified`（蓝色认证勾）——没有任何
///     认证数据源；
///   · `_subscriptionTier` 是一个 `final` 常量 `'免费用户'`，却被放进
///     金色渐变的 SVIP 徽章里：既不反映真实档位，样式还在暗示"尊贵身份"；
///   · `_getConstitution()` 在本地没有记录时**默认返回「平和质」**——
///     等于给一个从没做过体质测评的人下了一个体质结论。
///     养生类产品里这属于凭空断言，不是"默认值"。
///
/// 现在：未登录只显示未登录，登录后只显示取得到的真实数值，
/// 取不到就不显示这一项，**任何一处都不回退到固定值**。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../../data/storage/storage_manager.dart';

class ProfilePageV2 extends StatefulWidget {
  const ProfilePageV2({super.key});

  @override
  State<ProfilePageV2> createState() => _ProfilePageV2State();
}

class _ProfilePageV2State extends State<ProfilePageV2> {
  bool _loggedIn = false;
  /// null 表示**没取到**，与 0 不是一回事：0 会显示成「0」，null 显示成「—」。
  int? _favoriteCount;
  String? _userName;
  String? _subscriptionTier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loggedIn = StorageManager.user.isLoggedIn();
    final info = StorageManager.user.getUserInfo();
    final sub = StorageManager.user.getSubscription();

    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _userName = (info?['nickname'] ?? info?['name']) as String?;
        _subscriptionTier = sub?['tier_name'] as String? ?? sub?['tier'] as String?;
      });
    }

    // 本地存的昵称只在接口没给时兜底，且**只兜昵称**。
    if (loggedIn && (_userName == null || _userName!.isEmpty)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final name = prefs.getString('user_name');
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _userName = name);
        }
      } catch (_) {}
    }

    // 未登录就不去查收藏——原来这里写死 `user_id: 'guest'`，
    // 于是无论谁打开，看到的都是 guest 这个账号的数字。
    final userId = StorageManager.user.getUserId();
    if (!loggedIn || userId == null || userId.isEmpty) return;

    try {
      final resp = await ApiClient().get(
        '/api/v1/favorites',
        queryParameters: {'user_id': userId, 'limit': 1},
      );
      if (resp.data?['success'] == true) {
        final total = resp.data['data']?['total'];
        if (total is int && mounted) setState(() => _favoriteCount = total);
      }
    } catch (_) {
      // 取不到就保持 null —— 显示「—」，不回退成 0，更不回退成一个好看的数。
    }
  }

  /// 没做过体质测评就返回空串，由调用方隐藏这一块。
  /// **不再默认「平和质」**：那是在给没测过的人下结论。
  Future<String> _getConstitution() async {
    if (!_loggedIn) return '';
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('constitution_type') ?? '';
    } catch (_) {
      return '';
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
                        BoxShadow(color: ShunShiColors.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // 名字。**去掉了那个无条件渲染的 Icons.verified**——
                  // 没有任何认证数据源，给每个人（包括未登录）挂一个蓝勾
                  // 是在暗示一个不存在的状态。
                  Text(
                    _loggedIn ? (_userName?.isNotEmpty == true ? _userName! : '顺时用户') : '未登录',
                    style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                  if (!_loggedIn) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text('登录后查看我的收藏与订阅', style: TextStyle(
                        fontSize: 13, color: ShunShiColors.primary,
                      )),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // 体质标签：没测评过就是空串，这里整块不渲染。
                  FutureBuilder<String>(
                    future: _getConstitution(),
                    builder: (context, snap) => snap.hasData && snap.data!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: ShunShiColors.primaryLight.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ShunShiColors.primaryLight.withValues(alpha: 0.3)),
                              ),
                              child: Text('🌿 ${snap.data}', style: TextStyle(
                                fontSize: 12, color: ShunShiColors.primary,
                                fontWeight: FontWeight.w500,
                              )),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // 订阅徽章：**只有真的读到付费档位时才用金色**。
                  // 原来 `_subscriptionTier` 是一个写死的常量「免费用户」，
                  // 却被放进金色渐变里——既不反映真实档位，样式还在暗示身份。
                  if (_loggedIn && (_subscriptionTier?.isNotEmpty ?? false))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _isPaidTier
                            ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                            : null,
                        color: _isPaidTier ? null : ShunShiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_subscriptionTier!, style: TextStyle(
                        color: _isPaidTier ? Colors.white : ShunShiColors.textSecondary,
                        fontSize: 11, fontWeight: FontWeight.bold,
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                // 原来这一行是：积分 2560 ｜ 优惠券 3 张 ｜ 收藏 $_favoriteCount。
                // 前两个是**写死的字符串**，未登录也照显示。
                //
                // 积分与优惠券在服务端没有对应接口（后端没有积分体系），
                // 所以这里不是"换个数据源"，而是**先把它们撤掉**——
                // 等真有积分接口了再按接口加回来，不要先摆一个好看的数字。
                child: Row(
                  children: [
                    _buildStat('收藏', _loggedIn ? (_favoriteCount?.toString() ?? '—') : '—'),
                    Container(width: 1, height: 32, color: ShunShiColors.borderGhost),
                    _buildStat('订阅', _loggedIn ? (_subscriptionTier ?? '—') : '—'),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                    // 这个「立即邀请」原来是一个 **没有任何点击行为** 的
                    // Container——看起来能点，点了什么都不发生。
                    // 接到已有的 /family-invite 路由上。
                    InkWell(
                      onTap: () => context.push(_loggedIn ? '/family-invite' : '/login'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('立即邀请', style: TextStyle(
                          fontSize: 13, color: ShunShiColors.surface, fontWeight: FontWeight.w500,
                        )),
                      ),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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

  /// 档位名里出现这些词才当作付费档。读不到就按未付费处理——
  /// 宁可少给一个金色徽章，也不要给未付费用户一个"尊贵"的视觉暗示。
  bool get _isPaidTier {
    final t = _subscriptionTier ?? '';
    if (t.isEmpty) return false;
    const freeWords = ['免费', 'free', 'Free', 'FREE'];
    if (freeWords.any(t.contains)) return false;
    const paidWords = ['VIP', 'vip', 'SVIP', 'Pro', 'pro', '会员', '年卡', '月卡', 'Plus', 'plus'];
    return paidWords.any(t.contains);
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(children: [
        // 档位名可能比「2560」长得多，加上省略处理，别让它把这一行撑破。
        Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
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
