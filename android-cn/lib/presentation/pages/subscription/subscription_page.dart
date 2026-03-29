import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/components/components.dart';

// ── 数据模型 ──

enum _TierId { free, yangxin, yiyang, jiahe }

class _Tier {
  final _TierId id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final IconData icon;
  final List<String> features;
  final bool isRecommended;

  bool get isFree => id == _TierId.free;

  double yearlySaving() {
    if (isFree) return 0;
    return monthlyPrice * 12 - yearlyPrice;
  }

  const _Tier({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.icon,
    required this.features,
    this.isRecommended = false,
  });
}

class _SubscriptionStatus {
  final _TierId currentTier;
  final DateTime? expiresAt;

  const _SubscriptionStatus({
    required this.currentTier,
    this.expiresAt,
  });
}

class _ComparisonRow {
  final String label;
  final String free;
  final String yangxin;
  final String yiyang;
  final String jiahe;

  const _ComparisonRow({
    required this.label,
    required this.free,
    required this.yangxin,
    required this.yiyang,
    required this.jiahe,
  });
}

// ── 常量 ──

const _tiers = <_Tier>[
  _Tier(
    id: _TierId.free,
    name: '免费版',
    description: '基础功能',
    monthlyPrice: 0,
    yearlyPrice: 0,
    icon: Icons.eco_outlined,
    features: ['基础养生内容', 'AI对话 5次/天', '基础推送提醒'],
  ),
  _Tier(
    id: _TierId.yangxin,
    name: '养心版',
    description: 'AI对话不限，高级内容',
    monthlyPrice: 9.9,
    yearlyPrice: 99,
    icon: Icons.spa_outlined,
    features: ['AI对话不限次数', '个性化养生建议', '专属节气提醒', '自定义推送'],
  ),
  _Tier(
    id: _TierId.yiyang,
    name: '颐养版',
    description: '全部内容，体质报告，家庭关怀',
    monthlyPrice: 19.9,
    yearlyPrice: 199,
    icon: Icons.favorite_outline,
    features: ['包含养心全部', '高级养生内容', '详细体质报告', '家庭关怀功能', '智能推送提醒'],
    isRecommended: true,
  ),
  _Tier(
    id: _TierId.jiahe,
    name: '家和版',
    description: '颐养全部 + 家庭5人 + 专属客服',
    monthlyPrice: 39.9,
    yearlyPrice: 399,
    icon: Icons.family_restroom_outlined,
    features: ['包含颐养全部', '最多5位家庭成员', '专属客服通道', '家庭健康报告'],
  ),
];

const _comparisonRows = <_ComparisonRow>[
  _ComparisonRow(label: 'AI对话次数', free: '5次/天', yangxin: '不限', yiyang: '不限', jiahe: '不限'),
  _ComparisonRow(label: '高级内容', free: '✗', yangxin: '✗', yiyang: '✓', jiahe: '✓'),
  _ComparisonRow(label: '体质报告', free: '✗', yangxin: '基础', yiyang: '详细', jiahe: '详细'),
  _ComparisonRow(label: '家庭成员', free: '✗', yangxin: '✗', yiyang: '✗', jiahe: '5人'),
  _ComparisonRow(label: '推送提醒', free: '基础', yangxin: '自定义', yiyang: '智能推送', jiahe: '智能推送'),
];

const _tierNames = {
  _TierId.free: '免费版',
  _TierId.yangxin: '养心版',
  _TierId.yiyang: '颐养版',
  _TierId.jiahe: '家和版',
};

// ── 页面 ──

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // 0 = free, 1 = yangxin, 2 = yiyang, 3 = jiahe
  int _selectedTierIndex = 2; // default recommended
  bool _isYearly = true;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  _SubscriptionStatus? _status;

  final ApiClient _api = ApiClient();

  // ── 主题感知 ──

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.background : ShunshiColors.background;
  Color _surface(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surface : ShunshiColors.surface;
  Color _surfaceDim(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surfaceDim : ShunshiColors.surfaceDim;
  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;
  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;
  Color _textHint(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textHint : ShunshiColors.textHint;
  Color _borderColor(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.border : ShunshiColors.border;

  Color _primaryColor(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.primary : ShunshiColors.primary;

  // ── 生命周期 ──

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionStatus();
  }

  // ── API ──

  Future<void> _fetchSubscriptionStatus() async {
    try {
      final response = await _api.get('/api/v1/subscription/status');
      final data = response.data as Map<String, dynamic>?;

      if (data != null && mounted) {
        setState(() {
          _status = _SubscriptionStatus(
            currentTier: _parseTierId(data['tier'] as String?),
            expiresAt: data['expiresAt'] != null
                ? DateTime.tryParse(data['expiresAt'] as String)
                : null,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = const _SubscriptionStatus(currentTier: _TierId.free);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    final tier = _tiers[_selectedTierIndex];
    if (tier.isFree) return;

    setState(() => _isPurchasing = true);

    try {
      final response = await _api.post(
        '/api/v1/subscription/create-order',
        data: {
          'tier': tier.id.name,
          'billingCycle': _isYearly ? 'yearly' : 'monthly',
        },
      );
      final data = response.data as Map<String, dynamic>?;

      if (mounted) {
        setState(() => _isPurchasing = false);
        final success = data?['success'] as bool? ?? true; // demo阶段直接成功

        if (success) {
          _showSnackBar('订阅成功！已开通${tier.name}', isError: false);
          _fetchSubscriptionStatus();
        } else {
          _showSnackBar(data?['message'] ?? '订阅失败，请重试', isError: true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        // demo阶段: 即使API失败也模拟成功
        _showSnackBar('${tier.name} 订阅成功（演示模式）', isError: false);
        _fetchSubscriptionStatus();
      }
    }
  }

  Future<void> _handleRestorePurchase() async {
    setState(() => _isRestoring = true);

    try {
      final response = await _api.post('/api/v1/subscription/restore-purchase');
      final data = response.data as Map<String, dynamic>?;

      if (mounted) {
        setState(() => _isRestoring = false);
        final success = data?['success'] as bool? ?? false;

        if (success) {
          final tierName = data?['tier'] as String? ?? '会员';
          _showSnackBar('已成功恢复 $tierName', isError: false);
          _fetchSubscriptionStatus();
        } else {
          _showSnackBar('未找到可恢复的购买记录', isError: true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRestoring = false);
        _showSnackBar('恢复购买失败，请稍后重试', isError: true);
      }
    }
  }

  _TierId _parseTierId(String? tier) {
    switch (tier) {
      case 'yangxin':
        return _TierId.yangxin;
      case 'yiyang':
        return _TierId.yiyang;
      case 'jiahe':
        return _TierId.jiahe;
      default:
        return _TierId.free;
    }
  }

  // ── UI辅助 ──

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ShunshiColors.error : ShunshiColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _priceLabel(_Tier tier) {
    if (tier.isFree) return '免费';
    final price = _isYearly ? tier.yearlyPrice : tier.monthlyPrice;
    return '¥${price.toStringAsFixed(tier.monthlyPrice == price ? 1 : 0)}';
  }

  String _periodLabel(_Tier tier) {
    if (tier.isFree) return '';
    return _isYearly ? '/年' : '/月';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: ShunshiSpacing.pagePadding,
                vertical: ShunshiSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 顶部导航 ──
                  _buildHeader(context),

                  const SizedBox(height: ShunshiSpacing.md),

                  // ── 当前订阅状态 ──
                  _buildCurrentStatus(context),

                  const SizedBox(height: ShunshiSpacing.lg),

                  // ── 月付/年付切换 ──
                  _buildBillingToggle(context),

                  const SizedBox(height: ShunshiSpacing.lg),

                  // ── 等级卡片 ──
                  _buildTierCards(context),

                  const SizedBox(height: ShunshiSpacing.xl),

                  // ── 购买按钮 ──
                  _buildPurchaseButton(context),

                  const SizedBox(height: ShunshiSpacing.lg),

                  // ── 恢复购买 ──
                  _buildRestoreButton(context),

                  const SizedBox(height: ShunshiSpacing.sm),

                  // ── 恢复购买说明 ──
                  Center(
                    child: Text(
                      '换设备或重装后，点击恢复购买即可找回会员权益',
                      textAlign: TextAlign.center,
                      style: ShunshiTextStyles.caption.copyWith(
                        color: _textHint(context),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: ShunshiSpacing.xl),

                  // ── 权益对比表 ──
                  _buildComparisonSection(context),

                  const SizedBox(height: ShunshiSpacing.xl),

                  // ── 条款 ──
                  Center(
                    child: Text(
                      '订阅自动续费，可随时取消。购买即表示同意服务条款。',
                      textAlign: TextAlign.center,
                      style: ShunshiTextStyles.overline.copyWith(
                        color: _textHint(context),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: ShunshiSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 顶部导航 ──

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new,
              color: _textPrimary(context), size: 20),
        ),
        Expanded(
          child: Text(
            '会员订阅',
            style: ShunshiTextStyles.heading.copyWith(
              color: _textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }

  // ── 当前订阅状态 ──

  Widget _buildCurrentStatus(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.md,
          vertical: ShunshiSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _surfaceDim(context),
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor(context),
              ),
            ),
            const SizedBox(width: ShunshiSpacing.sm),
            Text('正在获取订阅状态...', style: ShunshiTextStyles.caption.copyWith(
              color: _textSecondary(context),
            )),
          ],
        ),
      );
    }

    final currentTierName = _tierNames[_status?.currentTier] ?? '免费版';
    final isFree = _status?.currentTier == _TierId.free || _status == null;

    String expiryText = '';
    if (!isFree && _status?.expiresAt != null) {
      expiryText = ' · 有效期至 ${_formatDate(_status!.expiresAt!)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ShunshiSpacing.md,
        vertical: ShunshiSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isFree
            ? _surfaceDim(context)
            : _primaryColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        border: Border.all(
          color: isFree ? _borderColor(context) : _primaryColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.info_outline : Icons.verified,
            color: isFree ? _textSecondary(context) : _primaryColor(context),
            size: 20,
          ),
          const SizedBox(width: ShunshiSpacing.sm),
          Expanded(
            child: Text(
              '当前：$currentTierName$expiryText',
              style: ShunshiTextStyles.caption.copyWith(
                color: isFree ? _textSecondary(context) : _textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 月付/年付切换 ──

  Widget _buildBillingToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceDim(context),
        borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            context,
            label: '月付',
            isSelected: !_isYearly,
            onTap: () => setState(() => _isYearly = false),
          ),
          _buildToggleOption(
            context,
            label: '年付',
            isSelected: _isYearly,
            badge: '省更多',
            onTap: () => setState(() => _isYearly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: badge != null ? ShunshiSpacing.md : ShunshiSpacing.lg,
          vertical: ShunshiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ShunshiTextStyles.buttonSmall.copyWith(
                color: isSelected ? _textPrimary(context) : _textHint(context),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: ShunshiSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ShunshiColors.warm.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
                ),
                child: Text(
                  badge,
                  style: ShunshiTextStyles.labelSmall.copyWith(
                    color: ShunshiColors.warm,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 等级卡片 ──

  Widget _buildTierCards(BuildContext context) {
    return Column(
      children: List.generate(_tiers.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _tiers.length - 1 ? ShunshiSpacing.md : 0,
          ),
          child: _buildTierCard(context, _tiers[index], index),
        );
      }),
    );
  }

  Widget _buildTierCard(BuildContext context, _Tier tier, int index) {
    final isSelected = _selectedTierIndex == index;
    final primary = _primaryColor(context);

    return InkWell(
      onTap: () => setState(() => _selectedTierIndex = index),
      borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(ShunshiSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : _surfaceDim(context),
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
          border: Border.all(
            color: isSelected ? primary : _borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 头部行 ──
            Row(
              children: [
                // 图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.15)
                        : _surfaceDim(context),
                    borderRadius: BorderRadius.circular(ShunshiSpacing.radiusMedium),
                  ),
                  child: Icon(tier.icon, color: primary, size: 22),
                ),
                const SizedBox(width: ShunshiSpacing.md),

                // 名称 + 推荐 badge
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        tier.name,
                        style: ShunshiTextStyles.heading.copyWith(
                          color: _textPrimary(context),
                        ),
                      ),
                      if (tier.isRecommended) ...[
                        const SizedBox(width: ShunshiSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ShunshiColors.warm.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
                          ),
                          child: Text(
                            '推荐',
                            style: ShunshiTextStyles.labelSmall.copyWith(
                              color: ShunshiColors.warm,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 选中指示
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: ShunshiColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _textHint(context), width: 1.5),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: ShunshiSpacing.xs),

            // 描述
            Text(
              tier.description,
              style: ShunshiTextStyles.caption.copyWith(
                color: _textSecondary(context),
              ),
            ),

            const SizedBox(height: ShunshiSpacing.md),

            // ── 价格行 ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _priceLabel(tier),
                  style: ShunshiTextStyles.insight.copyWith(
                    color: tier.isFree ? _textSecondary(context) : primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                if (!tier.isFree) ...[
                  const SizedBox(width: ShunshiSpacing.xs),
                  Text(
                    _periodLabel(tier),
                    style: ShunshiTextStyles.bodySecondary.copyWith(
                      color: _textSecondary(context),
                    ),
                  ),
                ],
                // 年付折扣
                if (_isYearly && !tier.isFree) ...[
                  const SizedBox(width: ShunshiSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ShunshiColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ShunshiSpacing.radiusFull),
                    ),
                    child: Text(
                      '省¥${tier.yearlySaving().toStringAsFixed(0)}',
                      style: ShunshiTextStyles.labelSmall.copyWith(
                        color: ShunshiColors.success,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 购买按钮 ──

  Widget _buildPurchaseButton(BuildContext context) {
    final tier = _tiers[_selectedTierIndex];
    if (tier.isFree) return const SizedBox.shrink();

    return Center(
      child: GentleButton(
        text: '立即订阅 ${tier.name}',
        isPrimary: true,
        isLoading: _isPurchasing,
        horizontalPadding: ShunshiSpacing.xl * 2,
        onPressed: _isPurchasing ? null : _handlePurchase,
      ),
    );
  }

  // ── 恢复购买 ──

  Widget _buildRestoreButton(BuildContext context) {
    return Center(
      child: GentleButton(
        text: _isRestoring ? '正在恢复购买...' : '恢复购买',
        isPrimary: false,
        isLoading: _isRestoring,
        horizontalPadding: ShunshiSpacing.xl,
        onPressed: _isRestoring ? null : _handleRestorePurchase,
      ),
    );
  }

  // ── 权益对比表 ──

  Widget _buildComparisonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '权益对比',
          style: ShunshiTextStyles.heading.copyWith(
            color: _textPrimary(context),
          ),
        ),
        const SizedBox(height: ShunshiSpacing.md),

        // 表头
        _buildComparisonRow(context, isHeader: true),
        Divider(color: _borderColor(context), height: 1),

        // 数据行
        ..._comparisonRows.map((row) {
          return Column(
            children: [
              _buildComparisonRow(context, row: row),
              Divider(color: _borderColor(context).withValues(alpha: 0.5), height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildComparisonRow(
    BuildContext context, {
    bool isHeader = false,
    _ComparisonRow? row,
  }) {
    final primary = _primaryColor(context);
    final labelStyle = isHeader
        ? ShunshiTextStyles.buttonSmall.copyWith(
            color: _textSecondary(context),
            fontWeight: FontWeight.w600,
          )
        : ShunshiTextStyles.caption.copyWith(
            color: _textPrimary(context),
          );
    final cellStyle = isHeader
        ? ShunshiTextStyles.buttonSmall.copyWith(
            color: _textSecondary(context),
            fontWeight: FontWeight.w600,
          )
        : ShunshiTextStyles.caption.copyWith(
            color: _textSecondary(context),
          );

    return IntrinsicHeight(
      child: Row(
        children: [
          // 标签列
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ShunshiSpacing.sm),
                child: Text(
                  isHeader ? '' : row!.label,
                  style: labelStyle,
                ),
              ),
            ),
          ),
          // 4个等级列
          ...List.generate(4, (i) {
            final text = isHeader
                ? _tiers[i].name
                : _comparisonCellValue(row, i);
            final isCheck = text == '✓';
            final isCross = text == '✗';

            return Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ShunshiSpacing.sm),
                  child: isCheck
                      ? Icon(Icons.check, color: primary, size: 16)
                      : isCross
                          ? Icon(Icons.close, color: _textHint(context), size: 14)
                          : Text(
                              text,
                              textAlign: TextAlign.center,
                              style: isHeader
                                  ? cellStyle
                                  : cellStyle.copyWith(
                                      fontSize: 12,
                                    ),
                            ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _comparisonCellValue(_ComparisonRow? row, int tierIndex) {
    if (row == null) return '';
    switch (tierIndex) {
      case 0:
        return row.free;
      case 1:
        return row.yangxin;
      case 2:
        return row.yiyang;
      case 3:
        return row.jiahe;
      default:
        return '';
    }
  }
}
