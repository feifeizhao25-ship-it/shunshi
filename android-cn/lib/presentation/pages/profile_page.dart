import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../data/network/api_client.dart';
import '../../../data/storage/storage_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final client = ApiClient();
      final response = await client.get('/api/v1/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _userInfo = Map<String, dynamic>.from(response.data as Map);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {
      // API failed, fall back to local data
    }

    // Fallback to local storage
    if (mounted) {
      setState(() {
        _userInfo = StorageManager.user.getUserInfo() ??
            {
              'name': '用户',
              'nickname': '用户',
              'avatar': null,
              'subscription_type': 'free',
              'subscription_label': '免费用户',
              'member_since': '2024-01-01',
              'health_stage': null,
            };
        _isLoading = false;
      });
    }
  }

  String get _displayName =>
      _userInfo?['nickname'] ?? _userInfo?['name'] ?? '用户';

  String get _avatarLetter {
    final name = _displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get _subscriptionLabel =>
      _userInfo?['subscription_label'] ?? '免费版';

  String get _memberSince {
    final raw = _userInfo?['member_since'] as String?;
    if (raw == null) return '';
    try {
      final year = DateTime.parse(raw).year;
      return '$year年加入';
    } catch (_) {
      return raw;
    }
  }

  String get _healthStage {
    final stage = _userInfo?['health_stage'] as String?;
    return stage ?? '压力阶段';
  }

  bool get _isPremium =>
      _userInfo?['subscription_type'] != null &&
      _userInfo?['subscription_type'] != 'free';

  // ── theme helpers ──

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.background : ShunshiColors.background;

  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;

  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;

  Color _textHint(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textHint : ShunshiColors.textHint;

  Color _divider(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.divider : ShunshiColors.divider;

  Color _surface(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surface : ShunshiColors.surface;

  Color _error(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.error : ShunshiColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ShunshiColors.primary,
                strokeWidth: 2,
              ),
            )
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── 顶部用户区（绿色渐变，圆角仅底部） ──
                    _buildUserHeader(context),

                    const SizedBox(height: 12),

                    // ── 分组卡片 ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ShunshiSpacing.pagePadding,
                      ),
                      child: Column(
                        children: [
                          // 个人信息
                          _buildGroupCard(
                            context,
                            emoji: '👤',
                            title: '个人信息',
                            items: [
                              ('我的体质', '/constitution'),
                              ('养生记录', '/records'),
                              ('我的收藏', null),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 家庭
                          _buildGroupCard(
                            context,
                            emoji: '👨‍👩‍👧‍👦',
                            title: '家庭',
                            items: [
                              ('家庭成员', '/family'),
                              ('关怀提醒设置', '/family'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 设置
                          _buildGroupCard(
                            context,
                            emoji: '⚙️',
                            title: '设置',
                            items: [
                              ('通知设置', '/settings'),
                              ('隐私设置', '/settings'),
                              ('免打扰时间', '/settings'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 订阅
                          _buildSubscriptionCard(context),
                          const SizedBox(height: 32),

                          // ── 底部信息 ──
                          _buildFooter(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== 顶部用户区 ====================

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: ShunshiSpacing.xl,
        bottom: ShunshiSpacing.xl,
        left: ShunshiSpacing.pagePadding,
        right: ShunshiSpacing.pagePadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B9E7E), Color(0xFFB5C7A8)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 头像：圆形Container + 首字母
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _avatarLetter,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ShunshiSpacing.md),
            // 昵称 + 阶段 + 加入时间
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_isPremium ? '养心会员' : '免费用户'} · $_healthStage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  if (_memberSince.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _memberSince,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 通用分组卡片 ====================

  Widget _buildGroupCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required List<(String, String?)> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: ShunshiTextStyles.heading.copyWith(
                    fontSize: 16,
                    color: _textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: _divider(context),
            ),
          ),
          // 列表项
          ...List.generate(items.length, (index) {
            final (label, route) = items[index];
            return _buildMenuItem(
              context,
              label: label,
              onTap: route != null ? () => context.push(route) : null,
              isLast: index == items.length - 1,
            );
          }),
        ],
      ),
    );
  }

  // ==================== 菜单项 ====================

  Widget _buildMenuItem(
    BuildContext context, {
    required String label,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ShunshiTextStyles.body.copyWith(
                  fontSize: 15,
                  height: 1.0,
                  color: _textPrimary(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _textHint(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 订阅卡片 ====================

  Widget _buildSubscriptionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '订阅',
                  style: ShunshiTextStyles.heading.copyWith(
                    fontSize: 16,
                    color: _textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: _divider(context)),
          ),
          // 当前等级
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Text(
                    '当前：',
                    style: ShunshiTextStyles.body.copyWith(
                      fontSize: 15,
                      height: 1.0,
                      color: _textSecondary(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isPremium
                          ? ShunshiColors.warm.withValues(alpha: 0.15)
                          : ShunshiColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _subscriptionLabel,
                      style: ShunshiTextStyles.body.copyWith(
                        fontSize: 13,
                        height: 1.0,
                        fontWeight: FontWeight.w500,
                        color: _isPremium
                            ? ShunshiColors.warm
                            : ShunshiColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: _divider(context)),
          ),
          // 升级按钮
          InkWell(
            onTap: () => context.push('/subscription'),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isPremium ? '管理订阅' : '升级养心版',
                      style: ShunshiTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.0,
                        color: ShunshiColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _textHint(context),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 底部 ====================

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        // 版本号
        Text(
          '顺时 v1.0.0',
          style: ShunshiTextStyles.caption.copyWith(
            color: _textHint(context),
          ),
        ),
        const SizedBox(height: 12),

        // 隐私政策 / 用户协议
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Text(
                '隐私政策',
                style: ShunshiTextStyles.caption.copyWith(
                  color: _textSecondary(context),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              '  ·  ',
              style: ShunshiTextStyles.caption.copyWith(
                color: _textHint(context),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                '用户协议',
                style: ShunshiTextStyles.caption.copyWith(
                  color: _textSecondary(context),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 退出登录
        GestureDetector(
          onTap: () => _handleLogout(context),
          child: Text(
            '退出登录',
            style: ShunshiTextStyles.button.copyWith(
              color: _error(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 退出登录 ====================

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '退出登录',
          style: ShunshiTextStyles.heading,
        ),
        content: Text(
          '确定要退出登录吗？',
          style: ShunshiTextStyles.bodySecondary.copyWith(
            color: _textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: ShunshiTextStyles.button.copyWith(
                color: _textSecondary(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
            child: Text(
              '退出',
              style: ShunshiTextStyles.button.copyWith(
                color: _error(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // 清除本地token和数据
    await StorageManager.user.clearToken();
    await StorageManager.user.setLoggedIn(false);
    await StorageManager.clearAll();

    if (mounted) {
      context.go('/login');
    }
  }
}
