/// 会员订阅中心 — 对齐UI参考 _11
/// TopBar(返回+会员中心+帮助) → Hero会员卡 → 订阅方案(年度/月度/家庭) → 会员权益(5项) → FAQ → 浮动底部CTA
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class MembershipCenterPage extends StatefulWidget {
  const MembershipCenterPage({super.key});

  @override
  State<MembershipCenterPage> createState() => _MembershipCenterPageState();
}

class _MembershipCenterPageState extends State<MembershipCenterPage> {
  int _selectedTier = 0; // 0=annual, 1=monthly, 2=family

  static const _tiers = [
    _Tier('年度会员', '¥199', '¥299', '首年特惠 · 每日仅需 ¥0.54', '年度'),
    _Tier('月度卡', '¥25', null, '随用随开 · 自由续费', '月度'),
    _Tier('家庭卡', '¥299', null, '3人共享 · 健康互联', '家庭'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: ShunShiColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: ShunShiColors.primary),
                          ),
                        ),
                        const Text('会员中心', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        GestureDetector(
                          onTap: () => _showHelpSheet(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: ShunShiColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.help_outline, size: 20, color: ShunShiColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 48),
                      _buildTiers(),
                      const SizedBox(height: 64),
                      _buildPrivileges(),
                      const SizedBox(height: 64),
                      _buildFAQ(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                color: ShunShiColors.background.withValues(alpha: 0.85),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ShunShiColors.surfaceVariant,
                            border: Border.all(color: ShunShiColors.background, width: 2),
                          ),
                          child: const Icon(Icons.person, size: 14, color: ShunShiColors.secondary),
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ShunShiColors.surfaceVariant,
                              border: Border.all(color: ShunShiColors.background, width: 2),
                            ),
                            child: const Icon(Icons.person, size: 14, color: ShunShiColors.secondary),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-16, 0),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ShunShiColors.surfaceContainerLow,
                              border: Border.all(color: ShunShiColors.background, width: 2),
                            ),
                            child: Center(
                              child: Text('+12k', style: TextStyle(
                                fontSize: 7, fontWeight: FontWeight.w700,
                                color: ShunShiColors.secondary,
                              )),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('已有 1.2 万用户开通年度会员', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: ShunShiColors.secondary,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShunShiColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          shadowColor: ShunShiColors.primary.withValues(alpha: 0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium, size: 22),
                            const SizedBox(width: 8),
                            Text('立即开通 · ${_tiers[_selectedTier].label}', style: TextStyle(
                              fontSize: 18, letterSpacing: 3,
                              fontFamily: ShunShiTypography.serifFamily,
                              fontWeight: FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('开通即代表您同意《会员服务协议》与《隐私政策》', style: TextStyle(
                      fontSize: 9, color: ShunShiColors.secondary.withValues(alpha: 0.6),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubscribe() {
    final tier = _tiers[_selectedTier];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在发起${tier.label}订阅支付（${tier.price}）…'),
        action: SnackBarAction(
          label: '了解详情',
          onPressed: () => _showPaymentStub(context, tier),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    // TODO: integrate real payment SDK
    _showPaymentStub(context, tier);
  }

  void _showPaymentStub(BuildContext context, _Tier tier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ShunShiColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Icon(Icons.payment, size: 48, color: ShunShiColors.primary),
          const SizedBox(height: 16),
          Text('${tier.label} · ${tier.price}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          Text('支付功能即将上线，敬请期待', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('我知道了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ShunShiColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('帮助中心', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily)),
          const SizedBox(height: 16),
          Text('如有任何问题，请联系：', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
          const SizedBox(height: 8),
          Text('support@shunshi.health', style: TextStyle(fontSize: 14, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('客服微信：ShunShi_Health', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ShunShiColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ShunShiColors.primary.withValues(alpha: 0.3),
            blurRadius: 24, offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREMIUM MEMBERSHIP', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.8),
                  )),
                  const SizedBox(height: 4),
                  const Text('ShunShi AI', style: TextStyle(
                    fontSize: 28, fontStyle: FontStyle.italic,
                    fontFamily: ShunShiTypography.serifFamily,
                    color: Colors.white,
                  )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ShunShiColors.apricotLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('SVIP 尊享', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                  color: ShunShiColors.primary,
                )),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('开启您的智能养生之旅', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.7),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: ShunShiColors.apricotLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('已为您定制 128 条健康建议', style: TextStyle(
                    fontSize: 11,
                    color: ShunShiColors.apricotLight,
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiers() {
    return Column(
      children: [
        // Annual plan
        GestureDetector(
          onTap: () => setState(() => _selectedTier = 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _selectedTier == 0 ? ShunShiColors.primary : ShunShiColors.apricotLight.withValues(alpha: 0.3)),
              boxShadow: ShunShiShadows.sm,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShunShiColors.secondary,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text('RECOMMENDED', style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 3,
                      color: Colors.white,
                    )),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Radio<int>(value: 0, groupValue: _selectedTier, onChanged: (v) => setState(() => _selectedTier = v!), activeColor: ShunShiColors.primary),
                          const Text('年度会员', style: TextStyle(
                            fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
                            color: ShunShiColors.primary,
                          )),
                        ]),
                        const SizedBox(height: 4),
                        Text('首年特惠 · 每日仅需 ¥0.54', style: TextStyle(
                          fontSize: 12, color: ShunShiColors.secondary,
                        )),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('¥299', style: TextStyle(
                          fontSize: 10, color: ShunShiColors.secondary,
                          decoration: TextDecoration.lineThrough,
                        )),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text('¥', style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
                            Text('199', style: TextStyle(
                              fontSize: 30, fontFamily: ShunShiTypography.serifFamily,
                              fontWeight: FontWeight.w700,
                              color: ShunShiColors.primary,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Monthly + Family
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTier = 1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: _selectedTier == 1 ? Border.all(color: ShunShiColors.primary) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Radio<int>(value: 1, groupValue: _selectedTier, onChanged: (v) => setState(() => _selectedTier = v!), activeColor: ShunShiColors.primary, visualDensity: VisualDensity.compact),
                        const Text('月度卡', style: TextStyle(
                          fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('¥', style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
                          Text('25', style: TextStyle(
                            fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
                            fontWeight: FontWeight.w700,
                            color: ShunShiColors.primary,
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('随用随开 · 自由续费', style: TextStyle(fontSize: 9, color: ShunShiColors.secondary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTier = 2),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: _selectedTier == 2 ? Border.all(color: ShunShiColors.primary) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Radio<int>(value: 2, groupValue: _selectedTier, onChanged: (v) => setState(() => _selectedTier = v!), activeColor: ShunShiColors.primary, visualDensity: VisualDensity.compact),
                        const Text('家庭卡', style: TextStyle(
                          fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('¥', style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
                          Text('299', style: TextStyle(
                            fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
                            fontWeight: FontWeight.w700,
                            color: ShunShiColors.primary,
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('3人共享 · 健康互联', style: TextStyle(fontSize: 9, color: ShunShiColors.secondary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivileges() {
    final items = [
      _Privilege(Icons.auto_awesome, 'AI私人订制方案', '基于二十四节气与体质实时调整的个性化调理建议。', ShunShiColors.primaryContainer),
      _Privilege(Icons.restaurant_menu, '全站食谱解锁', '5000+ 药膳食谱，包含详细营养成分与时令搭配。', ShunShiColors.apricotLight),
      _Privilege(Icons.headphones, '高保真音频随心听', '沉浸式冥想导引、中医名家访谈，高品质声学体验。', ShunShiColors.surfaceVariant),
      _Privilege(Icons.family_restroom, '家庭成员健康互联', '一人订阅，全家守护。实时关注家人的健康动态。', ShunShiColors.apricotLight),
      _Privilege(Icons.military_tech, '专属会员勋章', '独有的身份标识，记录您的养生打卡每一刻荣誉。', ShunShiColors.primaryContainer),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('会员尊享权益', style: TextStyle(
          fontSize: 22, fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        const SizedBox(height: 28),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, size: 28, color: ShunShiColors.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(
                      fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
                      color: ShunShiColors.textPrimary,
                    )),
                    const SizedBox(height: 4),
                    Text(item.desc, style: TextStyle(
                      fontSize: 12, height: 1.6,
                      color: ShunShiColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      _FAQ('如何取消自动续费？', '您可以在"我的-设置-订阅管理"中随时取消，取消后不影响当前周期的会员使用。'),
      _FAQ('家庭卡如何邀请成员？', '购买成功后，在会员中心点击"家庭管理"生成专属分享码，发送给家人即可完成绑定。'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('常见问题', style: TextStyle(
          fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        const SizedBox(height: 20),
        ...faqs.map((faq) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.question, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: ShunShiColors.textPrimary,
                )),
                const SizedBox(height: 8),
                Text(faq.answer, style: TextStyle(
                  fontSize: 12, height: 1.7,
                  color: ShunShiColors.secondary,
                )),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _Tier {
  final String name;
  final String price;
  final String? originalPrice;
  final String desc;
  final String label;
  const _Tier(this.name, this.price, this.originalPrice, this.desc, this.label);
}

class _Privilege {
  final IconData icon;
  final String title;
  final String desc;
  final Color bgColor;
  const _Privilege(this.icon, this.title, this.desc, this.bgColor);
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ(this.question, this.answer);
}
