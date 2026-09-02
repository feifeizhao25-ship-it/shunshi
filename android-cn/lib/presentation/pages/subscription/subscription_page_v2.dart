import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design_system/theme.dart';
import '../../../data/datasources/subscription_service.dart';
import '../../../data/models/subscription.dart';
import '../../../data/services/wechat_pay_client.dart';

class SubscriptionPageV2 extends StatefulWidget {
  const SubscriptionPageV2({super.key});

  @override
  State<SubscriptionPageV2> createState() => _SubscriptionPageV2State();
}

class _SubscriptionPageV2State extends State<SubscriptionPageV2> {
  List<SubscriptionPlan> _plans = [];
  UserSubscriptionStatus? _currentStatus;
  bool _loading = true;
  String? _purchasingPlanId;
  String? _orderMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SubscriptionService.getPlans(),
        SubscriptionService.getCurrentStatus(),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<SubscriptionPlan>;
          _currentStatus = results[1] as UserSubscriptionStatus;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(SubscriptionPlan plan) async {
    if (plan.priceCents == 0) {
      _showToast('当前已是${plan.name}');
      return;
    }
    final paymentMethod = await _choosePaymentMethod();
    if (paymentMethod == null || !mounted) return;
    setState(() {
      _purchasingPlanId = plan.id;
      _orderMessage = null;
    });

    try {
      final order = await SubscriptionService.createOrder(
        plan.id,
        platform: paymentMethod,
        paymentScene: paymentMethod == 'wechat' && !kIsWeb ? 'app' : 'native',
      );
      if (order == null) {
        if (mounted) {
          setState(() => _purchasingPlanId = null);
          _showToast('创建订单失败，请稍后重试');
        }
        return;
      }

      // 扫码支付场景：展示支付信息
      if (mounted) {
        setState(() {
          _purchasingPlanId = null;
          _orderMessage =
              '订单已创建：¥${(order.amountCents / 100).toStringAsFixed(0)}\n请完成支付后刷新页面';
        });
        if (paymentMethod == 'wechat' && order.appPayParams != null) {
          final launched = await WechatPayClient.pay(order.appPayParams!);
          if (!launched) {
            _showToast('无法调起微信支付，请检查微信安装及应用签名配置');
            return;
          }
        } else if (paymentMethod == 'wechat' && order.paymentUrl != null) {
          await _showWechatQr(order.paymentUrl!);
        } else {
          final paymentUrl = order.paymentUrl;
          if (paymentUrl == null || paymentUrl.isEmpty) {
            _showToast('支付渠道未返回有效链接，请稍后重试');
            return;
          }
          final launched = await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            _showToast('无法打开支付宝，请检查是否已安装');
            return;
          }
        }
        final status = await SubscriptionService.pollOrderStatus(order.orderId);
        if (status == 'paid' && mounted) {
          await _loadData();
          _showToast('支付已确认，会员权益已生效');
        } else if (mounted) {
          _showToast('尚未收到支付确认，可稍后在会员中心刷新');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _purchasingPlanId = null);
        _showToast('购买失败：${e.toString()}');
      }
    }
  }

  Future<String?> _choosePaymentMethod() {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择支付方式',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble,
                  color: Color(0xFF07C160),
                ),
                title: const Text('微信支付'),
                subtitle: Text(kIsWeb ? '生成二维码后使用微信扫码' : '安全调起微信完成支付'),
                onTap: () => Navigator.pop(context, 'wechat'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF1677FF),
                ),
                title: const Text('支付宝'),
                subtitle: const Text('安全调起支付宝完成支付'),
                onTap: () => Navigator.pop(context, 'alipay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWechatQr(String codeUrl) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('微信扫码支付'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: codeUrl, size: 220, semanticsLabel: '微信支付二维码'),
            const SizedBox(height: 12),
            const Text('请使用微信扫描二维码。支付结果以服务端通知为准。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我已完成支付'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasingPlanId = 'restoring');
    final ok = await SubscriptionService.restorePurchases();
    if (mounted) {
      setState(() => _purchasingPlanId = null);
      if (ok) {
        await _loadData();
        _showToast('恢复购买成功');
      } else {
        _showToast('未找到可恢复的购买');
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShunShiColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '会员中心',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ShunShiColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              '恢复购买',
              style: TextStyle(
                fontSize: 13,
                color: ShunShiColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ShunShiColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: ShunShiColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentPlanBanner(),
                    const SizedBox(height: 20),
                    _buildPlans(),
                    const SizedBox(height: 24),
                    _buildBenefits(),
                    const SizedBox(height: 20),
                    _buildFAQ(),
                    if (_orderMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ShunShiColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: ShunShiColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _orderMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ShunShiColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            '支付安全由支付宝/微信支付提供保障',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    final planId = _currentStatus?.planId ?? 'free';
    final isActive = _currentStatus?.isActive ?? false;
    final days = _currentStatus?.dayRemaining ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: planId == 'free'
              ? [const Color(0xFF8B7355), const Color(0xFF6B5344)]
              : [ShunShiColors.primary, const Color(0xFF2D7A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'FREE',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (isActive && days > 0)
                Text(
                  '$days 天剩余',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE4C285),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentStatus?.planName ?? '免费版',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getPlanSubtitle(planId),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          if (planId != 'free' && isActive) ...[
            const SizedBox(height: 10),
            _buildFeatureRow('unlimited_chat', '无限聊天'),
            _buildFeatureRow('today_plan', '今日计划'),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String key, String label) {
    final available = _currentStatus?.features[key] ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: available ? const Color(0xFFE4C285) : Colors.white30,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: available ? Colors.white : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanSubtitle(String planId) {
    switch (planId) {
      case 'free':
        return '基础功能，满足日常养生需求';
      case 'yangxin':
        return '无限聊天 + 今日计划';
      case 'yiyang':
        return '深度建议 + 周总结';
      case 'jiahe':
        return '家庭共享（4席位）';
      default:
        return '';
    }
  }

  Widget _buildPlans() {
    final plans = _plans.where((p) => p.id != 'free').toList();
    final recommended = plans.firstWhere(
      (p) => p.isRecommended,
      orElse: () => plans.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择您的会员方案',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Recommended 年度 plan
        GestureDetector(
          onTap: () => _purchase(recommended),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ShunShiColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ShunShiColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ShunShiColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ShunShiColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4C285).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '年度特惠',
                        style: TextStyle(
                          fontSize: 10,
                          color: ShunShiColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recommended.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ShunShiColors.textPrimary,
                  ),
                ),
                Text(
                  '${recommended.periodName ?? ""} · 每日约 ¥${((recommended.priceYearlyCents ?? 0) / 36500).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ShunShiColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${(recommended.priceYearlyCents ?? 0) ~/ 100}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: ShunShiColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/年',
                        style: TextStyle(
                          fontSize: 13,
                          color: ShunShiColors.textTertiary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildPurchaseButton(recommended),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Monthly plans row
        Row(
          children: [
            for (final plan in plans.where((p) => p.id != recommended.id))
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: plan == plans.last ? 0 : 8),
                  child: _buildPlanCard(plan),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _currentStatus?.planId == plan.id;
    return GestureDetector(
      onTap: () => _purchase(plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? ShunShiColors.primary
                : ShunShiColors.borderGhost,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.priceCents > 0
                  ? '¥${plan.priceCents ~/ 100}/${plan.periodName ?? "月"}'
                  : '免费',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ShunShiColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: TextStyle(
                fontSize: 10,
                color: ShunShiColors.textTertiary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _buildPurchaseButton(plan),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(SubscriptionPlan plan) {
    final isPurchasing = _purchasingPlanId == plan.id;
    final isCurrent =
        _currentStatus?.planId == plan.id && _currentStatus?.isActive == true;

    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ShunShiColors.textTertiary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '当前',
          style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary),
        ),
      );
    }
    if (isPurchasing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: ShunShiColors.primary,
        ),
      );
    }
    return GestureDetector(
      onTap: () => _purchase(plan),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ShunShiColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '开通',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '会员尊享权益',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildBenefit(
          Icons.auto_awesome,
          'AI私人订制方案',
          '基于二十四节气与体质实时调整的个性化调理建议。',
        ),
        _buildBenefit(
          Icons.restaurant_menu,
          '完整内容库',
          '解锁当前已上架并持续更新的食养、作息与节气内容。',
        ),
        _buildBenefit(Icons.headphones, '会员音频', '按实际上架范围收听冥想导引与养生音频。'),
        _buildBenefit(
          Icons.family_restroom,
          '家庭成员关怀',
          '家和版最多提供4个家庭席位，并由成员自行控制共享范围。',
        ),
        _buildBenefit(
          Icons.insights,
          '长期趋势与周度报告',
          '在数据充足时生成趋势视图和周度深度报告，并明确数据范围。',
        ),
        const SizedBox(height: 8),
        Text(
          '当前支付宝方案为单次购买，不自动续费；支付前会再次展示金额与订单信息。',
          style: TextStyle(
            fontSize: 12,
            color: ShunShiColors.textTertiary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ShunShiColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: ShunShiColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: ShunShiColors.textTertiary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '如何取消自动续费？',
              style: TextStyle(
                fontSize: 14,
                color: ShunShiColors.textSecondary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: ShunShiColors.textTertiary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
