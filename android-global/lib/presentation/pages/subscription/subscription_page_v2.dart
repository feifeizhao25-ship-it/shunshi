import 'package:flutter/material.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../data/datasources/subscription_service.dart';
import '../../../data/models/subscription.dart';

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
      _showToast('Already subscribed to${plan.name}');
      return;
    }
    setState(() {
      _purchasingPlanId = plan.id;
      _orderMessage = null;
    });

    try {
      final order = await SubscriptionService.createOrder(plan.id);
      if (order == null) {
        if (mounted) {
          setState(() => _purchasingPlanId = null);
          _showToast('Order creation failed, please retry');
        }
        return;
      }

      // 扫码支付场景：展示支付信息
      if (mounted) {
        setState(() {
          _purchasingPlanId = null;
          _orderMessage = 'Order created：¥${(order.amountCents / 100).toStringAsFixed(0)}\nPlease complete payment and refresh';
        });
        // 模拟支付成功（开发模式）
        await _simulatePaymentSuccess(plan);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _purchasingPlanId = null);
        _showToast('Purchase failed：${e.toString()}');
      }
    }
  }

  Future<void> _simulatePaymentSuccess(SubscriptionPlan plan) async {
    // 开发模式：直接将本地订阅状态设为已购买
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan.id);
    await prefs.setBool('is_subscribed', true);
    if (mounted) {
      await _loadData();
      _showToast('Welcome to${plan.name}');
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasingPlanId = 'restoring');
    final ok = await SubscriptionService.restorePurchases();
    if (mounted) {
      setState(() => _purchasingPlanId = null);
      if (ok) {
        await _loadData();
        _showToast('Purchase restored');
      } else {
        _showToast('No purchases to restore');
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
    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShunShiColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Membership',
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
            child: Text(AppLocalizations.of(context).get('subscribe_restore'), style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: ShunShiColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          color: ShunShiColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ShunShiColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, color: ShunShiColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_orderMessage!, style: TextStyle(fontSize: 13, color: ShunShiColors.primary))),
                        ]),
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
            'Secure payment via Alipay/WeChat Pay',
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
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'FREE',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (isActive && days > 0)
              Text('$days days left', style: const TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
          ]),
          const SizedBox(height: 12),
          Text(
            _currentStatus?.planName ?? 'Free',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _getPlanSubtitle(planId),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          if (planId != 'free' && isActive) ...[
            const SizedBox(height: 10),
            _buildFeatureRow('unlimited_chat', 'Unlimited Chat'),
            _buildFeatureRow('today_plan', 'Daily Plan'),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String key, String label) {
    final available = _currentStatus?.features[key] ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(Icons.check_circle, color: available ? const Color(0xFFE4C285) : Colors.white30, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: available ? Colors.white : Colors.white30)),
      ]),
    );
  }

  String _getPlanSubtitle(String planId) {
    switch (planId) {
      case 'free': return 'Basic features for daily wellness';
      case 'yangxin': return 'Unlimited Chat + Daily Plan';
      case 'yiyang': return 'Deep advice + weekly summary';
      case 'jiahe': return 'Family sharing (4 seats)';
      default: return '';
    }
  }

  Widget _buildPlans() {
    final plans = _plans.where((p) => p.id != 'free').toList();
    final recommended = plans.firstWhere((p) => p.isRecommended, orElse: () => plans.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).get('subscribe_title'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
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
              boxShadow: [BoxShadow(color: ShunShiColors.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(6)),
                    child: Text(AppLocalizations.of(context).get('subscription_recommended'), style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE4C285).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(AppLocalizations.of(context).get('subscription_annual_deal'), style: TextStyle(fontSize: 10, color: ShunShiColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(recommended.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                Text('${recommended.periodName ?? ""} · Only ¥${(recommended.priceYearlyCents ?? 0) ~/ 36500}', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('¥${(recommended.priceYearlyCents ?? 0) ~/ 100}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: ShunShiColors.primary)),
                  const SizedBox(width: 6),
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(AppLocalizations.of(context).get('subscription_per_year'), style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary))),
                  const Spacer(),
                  _buildPurchaseButton(recommended),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Monthly plans row
        Row(children: [
          for (final plan in plans.where((p) => p.id != recommended.id))
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: plan == plans.last ? 0 : 8),
                child: _buildPlanCard(plan),
              ),
            ),
        ]),
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
          border: Border.all(color: isSelected ? ShunShiColors.primary : ShunShiColors.borderGhost),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(plan.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            plan.priceCents > 0 ? '¥${plan.priceCents ~/ 100}/${plan.periodName ?? "mo"}' : 'Free',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ShunShiColors.primary),
          ),
          const SizedBox(height: 4),
          Text(plan.description, style: TextStyle(fontSize: 10, color: ShunShiColors.textTertiary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          _buildPurchaseButton(plan),
        ]),
      ),
    );
  }

  Widget _buildPurchaseButton(SubscriptionPlan plan) {
    final isPurchasing = _purchasingPlanId == plan.id;
    final isCurrent = _currentStatus?.planId == plan.id && _currentStatus?.isActive == true;

    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: ShunShiColors.textTertiary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Text('Current', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      );
    }
    if (isPurchasing) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ShunShiColors.primary));
    }
    return GestureDetector(
      onTap: () => _purchase(plan),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(8)),
        child: Text('Subscribe', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBenefits() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Member Benefits', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
      const SizedBox(height: 12),
      _buildBenefit(Icons.auto_awesome, 'AI Personalized Plans', 'Wellness suggestions based on 24 solar terms and your constitution.'),
      _buildBenefit(Icons.restaurant_menu, 'All Recipes', '5,000+ food therapy recipes with nutrition info and seasonal pairing.'),
      _buildBenefit(Icons.headphones, 'Hi-Fi Audio', 'Immersive meditation guides and TCM expert interviews.'),
      _buildBenefit(Icons.family_restroom, 'Family Health', 'One subscription, whole family protected.'),
      _buildBenefit(Icons.military_tech, 'Member Badge', 'Exclusive badge celebrating your wellness milestones.'),
    ]);
  }

  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: ShunShiColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildFAQ() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.help_outline, color: ShunShiColors.textTertiary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('How to cancel auto-renewal?', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary))),
        Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
      ]),
    );
  }
}
