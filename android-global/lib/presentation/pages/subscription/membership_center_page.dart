/// 会员Subscription中心 — 对齐UI参考 _11
/// TopBar(返回+Membership+帮助) → Hero会员卡 → Subscription方案(年度/月度/家庭) → 会员权益(5项) → FAQ → 浮动底部CTA
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_singleton.dart';

class MembershipCenterPage extends StatelessWidget {
  const MembershipCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── TopAppBar ──
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
                            child: Icon(Icons.arrow_back_ios_new, size: 18, color: ShunShiColors.primary),
                          ),
                        ),
                        Text(AppLocalizations.of(context).t('subscription_membership'), style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        GestureDetector(
                          onTap: () => context.push('/help'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: ShunShiColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.help_outline, size: 20, color: ShunShiColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                  child: Column(
                    children: [
                      // Hero Card
                      _buildHeroCard(context),
                      SizedBox(height: 48),
                      // Subscription Tiers
                      _buildTiers(context),
                      SizedBox(height: 64),
                      // Privileges
                      _buildPrivileges(context),
                      SizedBox(height: 64),
                      // FAQ
                      _buildFAQ(context),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating Bottom CTA ──
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
                    // Social proof
                    Row(
                      children: [
                        // Stacked avatars
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ShunShiColors.surfaceVariant,
                            border: Border.all(color: ShunShiColors.background, width: 2),
                          ),
                          child: Icon(Icons.person, size: 14, color: ShunShiColors.secondary),
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
                            child: Icon(Icons.person, size: 14, color: ShunShiColors.secondary),
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
                        SizedBox(width: 12),
                        Text(AppLocalizations.of(context).t('subscription_over_12000_members_have_chosen_annual_plans'), style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: ShunShiColors.secondary,
                        )),
                      ],
                    ),
                    SizedBox(height: 16),
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {},
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
                            Icon(Icons.workspace_premium, size: 22),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context).t('subscription_subscribe_now'), style: TextStyle(
                              fontSize: 18, letterSpacing: 3,
                              fontFamily: ShunShiTypography.serifFamily,
                              fontWeight: FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('By subscribing you agree to the Terms of Service and Privacy Policy', style: TextStyle(
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

  Widget _buildHeroCard(BuildContext context) {
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
          // Top row
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
                  SizedBox(height: 4),
                  Text(AppLocalizations.of(context).t('profile_brand'), style: TextStyle(
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
                child: Text(AppLocalizations.of(context).t('subscription_svip_benefits'), style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                  color: ShunShiColors.primary,
                )),
              ),
            ],
          ),
          // Bottom row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).t('subscription_start_your_smart_wellness_journey'), style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.7),
              )),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: ShunShiColors.apricotLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context).t('subscription_128_personalized_health_suggestions_ready_for'), style: TextStyle(
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

  Widget _buildTiers(BuildContext context) {
    return Column(
      children: [
        // Annual plan (featured)
        GestureDetector(
          onTap: () {
            // Select annual plan — payment flow
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ShunShiColors.apricotLight.withValues(alpha: 0.3)),
              boxShadow: ShunShiShadows.sm,
            ),
            child: Stack(
              children: [
                // Recommended badge
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
                        Text(AppLocalizations.of(context).t('subscription_annual_plan'), style: TextStyle(
                          fontSize: 20, fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.primary,
                        )),
                        SizedBox(height: 4),
                        Text(AppLocalizations.of(context).t('subscription_first_year_deal_only_054day'), style: TextStyle(
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
                          children: [
                            Text('¥', style: TextStyle(
                              fontSize: 13, color: ShunShiColors.primary,
                            )),
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
        SizedBox(height: 12),
        // Monthly + Family grid
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Select monthly plan
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).t('subscription_monthly_plan'), style: TextStyle(
                        fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                        color: ShunShiColors.primary,
                      )),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('¥', style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
                          Text('25', style: TextStyle(
                            fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
                            fontWeight: FontWeight.w700,
                            color: ShunShiColors.primary,
                          )),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(AppLocalizations.of(context).t('subscription_flexible_cancel_anytime'), style: TextStyle(
                        fontSize: 9, color: ShunShiColors.secondary,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Select family plan
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).t('subscription_family_plan'), style: TextStyle(
                        fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                        color: ShunShiColors.primary,
                      )),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('¥', style: TextStyle(fontSize: 13, color: ShunShiColors.primary)),
                          Text('299', style: TextStyle(
                            fontSize: 24, fontFamily: ShunShiTypography.serifFamily,
                            fontWeight: FontWeight.w700,
                            color: ShunShiColors.primary,
                          )),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(AppLocalizations.of(context).t('subscription_3_members_health_sharing'), style: TextStyle(
                        fontSize: 9, color: ShunShiColors.secondary,
                      )),
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

  Widget _buildPrivileges(BuildContext context) {
    final items = [
      _Privilege(Icons.auto_awesome, 'AI Personalized Plans', 'Wellness suggestions based on 24 solar terms and your constitution.', ShunShiColors.primaryContainer),
      _Privilege(Icons.restaurant_menu, 'All Recipes', '5,000+ food therapy recipes with nutrition info and seasonal pairing.', ShunShiColors.apricotLight),
      _Privilege(Icons.headphones, 'Hi-Fi Audio', 'Immersive meditation guides and TCM expert interviews.', ShunShiColors.surfaceVariant),
      _Privilege(Icons.family_restroom, 'Family Health', 'One subscription, whole family protected. Real-time wellness updates.', ShunShiColors.apricotLight),
      _Privilege(Icons.military_tech, 'Member Badge', 'Exclusive identity badge for your wellness milestones.', ShunShiColors.primaryContainer),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).t('subscription_member_benefits'), style: TextStyle(
          fontSize: 22, fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        SizedBox(height: 28),
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
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(
                      fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
                      color: ShunShiColors.textPrimary,
                    )),
                    SizedBox(height: 4),
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

  Widget _buildFAQ(BuildContext context) {
    final faqs = [
      _FAQ('How to cancel auto-renewal?', 'Go to Profile > Settings > Subscription to cancel anytime. Current period remains active.'),
      _FAQ('How to invite family members?', 'After purchase, go to Membership > Family Management to generate a share code. Send it to family to join.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FAQ', style: TextStyle(
          fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.primary,
        )),
        SizedBox(height: 20),
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
                SizedBox(height: 8),
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
