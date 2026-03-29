import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../widgets/components/soft_card.dart';

/// Help Center & Trust FAQ — SEASONS Global
/// In-app support page for international users

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
          color: SeasonsColors.textPrimary,
        ),
        title: Text(
          'Help & Support',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search ──
            Container(
              decoration: BoxDecoration(
                color: SeasonsColors.surface,
                borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
                border: Border.all(color: SeasonsColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: SeasonsTextStyles.body.copyWith(
                  color: SeasonsColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: SeasonsColors.textHint,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SeasonsSpacing.lg,
                    vertical: SeasonsSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Quick Actions ──
            _buildSectionHeader('QUICK ACTIONS'),
            const SizedBox(height: SeasonsSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.mail_outline,
                    label: 'Email Us',
                    subtitle: 'Response in 24h',
                    onTap: () => _showEmailSupport(context),
                  ),
                ),
                const SizedBox(width: SeasonsSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.restore,
                    label: 'Restore',
                    subtitle: 'Subscription',
                    onTap: () => _showRestoreInfo(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── FAQ Categories ──
            _buildSectionHeader('FAQ'),
            const SizedBox(height: SeasonsSpacing.md),

            _buildFaqCategory(
              context,
              title: 'Getting Started',
              icon: '🌿',
              items: [
                _FaqItem(
                  question: 'What is SEASONS?',
                  answer: 'SEASONS is an AI calm lifestyle companion designed to help you slow down, breathe, and find calm in your everyday life. It provides daily insights, breathing exercises, reflection prompts, and seasonal living guidance — all through gentle, supportive AI conversations.\n\nSEASONS is not a medical service, therapy, or mental health treatment. It is a wellness tool designed to complement, not replace, professional care.',
                ),
                _FaqItem(
                  question: 'How do I get started?',
                  answer: 'After downloading SEASONS, you\'ll complete a brief onboarding (about 90 seconds) that helps us understand how you\'re feeling and what kind of support you\'re looking for. Based on this, SEASONS will provide personalized daily insights and gentle suggestions tailored to your needs.',
                ),
                _FaqItem(
                  question: 'Is SEASONS free to use?',
                  answer: 'Yes! SEASONS offers a Free tier that includes daily insights, basic reflection tracking, and access to seasonal content. Our Premium subscription unlocks unlimited AI conversations, the full content library, audio guides, and more. You can start a free trial to explore Premium features.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              title: 'Subscription & Billing',
              icon: '💳',
              items: [
                _FaqItem(
                  question: 'How do I cancel my subscription?',
                  answer: 'You can cancel your subscription at any time through your device\'s app store settings (App Store for iOS, Google Play for Android). Your access will continue until the end of your current billing period.\n\nFor iOS: Settings → Apple ID → Subscriptions → SEASONS → Cancel\nFor Android: Play Store → Profile → Payments & subscriptions → Subscriptions → SEASONS → Cancel',
                ),
                _FaqItem(
                  question: 'Can I restore my purchases?',
                  answer: 'Yes. If you\'ve reinstalled SEASONS or are setting it up on a new device, you can restore your purchases by going to Settings → Restore Purchases. This will reconnect your existing subscription to your account.',
                ),
                _FaqItem(
                  question: 'Do you offer refunds?',
                  answer: 'Refunds are processed through your app store. Apple and Google have their own refund policies, but typically allow refunds within a certain window after purchase. Please contact the respective app store support for refund requests.',
                ),
                _FaqItem(
                  question: 'What payment methods do you accept?',
                  answer: 'Payments are processed securely through Apple (iOS) and Google (Android). We accept all major credit cards, debit cards, and platform-specific payment methods supported by the app stores.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              title: 'Privacy & Data',
              icon: '🔒',
              items: [
                _FaqItem(
                  question: 'Is my data private?',
                  answer: 'Your privacy is fundamental to how SEASONS works. We collect only what\'s needed to provide your personalized experience:\n\n• Your reflections, preferences, and conversation history\n• Usage data to improve your experience\n\nWe do NOT sell your data. You can export or delete your data at any time through Settings → Privacy & Safety. SEASONS is designed to be transparent about what it remembers and gives you full control.',
                ),
                _FaqItem(
                  question: 'What data does SEASONS collect?',
                  answer: 'SEASONS may collect:\n• Account information (email, name) if you sign in\n• Your reflections, mood inputs, and journal entries\n• Conversation history with the AI\n• Preferences and settings you choose\n• Basic usage data (how often you open the app)\n\nWe do not collect sensitive medical information, and you can opt out of memory at any time.',
                ),
                _FaqItem(
                  question: 'How do I delete my account?',
                  answer: 'You can permanently delete your account and all associated data through Settings → Privacy & Safety → Delete Account. This will:\n• Remove your profile and preferences\n• Delete your reflection history\n• Clear your AI conversation memory\n• Cancel any active subscriptions\n\nThis action is permanent and cannot be undone.',
                ),
                _FaqItem(
                  question: 'Can I control what SEASONS remembers?',
                  answer: 'Yes. In Settings → Privacy & Safety, you can:\n• Toggle Memory on/off\n• Clear all memory at any time\n• See what preferences are stored\n\nWhen Memory is off, SEASONS will not use your past conversations to personalize responses. Each conversation starts fresh.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              title: 'AI Companion',
              icon: '🤖',
              items: [
                _FaqItem(
                  question: 'Is SEASONS a real AI?',
                  answer: 'Yes, SEASONS uses AI (large language models) to generate its responses and provide personalized guidance. We are transparent about this — SEASONS clearly identifies itself as an AI companion, not a human therapist, counselor, or medical professional.',
                ),
                _FaqItem(
                  question: 'Can SEASONS help with mental health issues?',
                  answer: 'SEASONS is a wellness and mindfulness tool, not a mental health service. It is not designed to diagnose, treat, or replace professional mental health care.\n\nIf you are experiencing a mental health crisis, please reach out to a qualified professional or a crisis helpline (988 in the US, 116 123 in the UK, or your local equivalent). SEASONS is here to support gentle daily wellness, not to replace clinical care.',
                ),
                _FaqItem(
                  question: 'Is SEASONS safe to talk to?',
                  answer: 'SEASONS has built-in safety measures to detect sensitive topics and provide appropriate responses. If you mention crisis or concerning situations, SEASONS will provide empathetic support and direct you to professional resources.\n\nSEASONS will never provide medical diagnoses, prescribe treatments, or pretend to be human. These boundaries are intentional and part of our commitment to safe, transparent AI.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              title: 'Family & Accounts',
              icon: '👨‍👩‍👧',
              items: [
                _FaqItem(
                  question: 'Can I share SEASONS with my family?',
                  answer: 'The Family plan includes up to 4 separate profiles, so each family member can have their own personalized SEASONS experience under one subscription. Each person\'s data, preferences, and history remain private to their own profile.',
                ),
                _FaqItem(
                  question: 'Is SEASONS suitable for children?',
                  answer: 'SEASONS is designed for adults (18+) and is not specifically designed for children. If you have teenagers who want to use SEASONS, we recommend reviewing the content together and ensuring parental guidance. SEASONS is not a replacement for professional care for young people experiencing mental health challenges.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              title: 'Technical Issues',
              icon: '⚙️',
              items: [
                _FaqItem(
                  question: 'Why isn\'t SEASONS responding?',
                  answer: 'If SEASONS seems slow or unresponsive:\n• Check your internet connection\n• Force close and reopen the app\n• Make sure you\'re on the latest version of SEASONS\n\nIf issues persist, please contact us at support@seasons.app with details about the problem.',
                ),
                _FaqItem(
                  question: 'How do I update SEASONS?',
                  answer: 'SEASONS updates automatically when a new version is available. To ensure you have the latest features and improvements:\n• iOS: App Store → your profile → Available Updates\n• Android: Play Store → Manage apps → SEASONS → Update',
                ),
              ],
            ),

            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Trust & Safety ──
            _buildSectionHeader('TRUST & SAFETY'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildTrustCard(context),

            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Contact ──
            _buildSectionHeader('CONTACT US'),
            const SizedBox(height: SeasonsSpacing.md),
            SoftCard(
              borderRadius: SeasonsSpacing.radiusLarge,
              padding: const EdgeInsets.all(SeasonsSpacing.lg),
              onTap: () => _showEmailSupport(context),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SeasonsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('📧', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: SeasonsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'support@seasons.app',
                          style: SeasonsTextStyles.body.copyWith(
                            color: SeasonsColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We typically respond within 24 hours',
                          style: SeasonsTextStyles.caption.copyWith(
                            color: SeasonsColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: SeasonsColors.textTertiary, size: 18),
                ],
              ),
            ),

            const SizedBox(height: SeasonsSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: SeasonsTextStyles.caption.copyWith(
        color: SeasonsColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFaqCategory(
    BuildContext context, {
    required String title,
    required String icon,
    required List<_FaqItem> items,
  }) {
    final filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.question.toLowerCase().contains(_searchQuery) ||
          item.answer.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: SeasonsSpacing.sm),
            Text(
              title,
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: SeasonsSpacing.md),
        ...filtered.map((item) => _FaqExpandable(item: item)),
        const SizedBox(height: SeasonsSpacing.lg),
      ],
    );
  }

  Widget _buildTrustCard(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SeasonsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🛟', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Text(
                  'SEASONS Safety Commitment',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.md),
          _trustItem(Icons.check_circle_outline, 'Not medical advice'),
          const SizedBox(height: SeasonsSpacing.sm),
          _trustItem(Icons.check_circle_outline, 'Not therapy or diagnosis'),
          const SizedBox(height: SeasonsSpacing.sm),
          _trustItem(Icons.check_circle_outline, 'You control your data'),
          const SizedBox(height: SeasonsSpacing.sm),
          _trustItem(Icons.check_circle_outline, 'Transparent AI disclosure'),
          const SizedBox(height: SeasonsSpacing.sm),
          _trustItem(Icons.check_circle_outline, 'No manipulative engagement'),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SeasonsColors.primary),
        const SizedBox(width: SeasonsSpacing.sm),
        Text(
          text,
          style: SeasonsTextStyles.caption.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showEmailSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email us at support@seasons.app'),
        backgroundColor: SeasonsColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRestoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Purchases',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'To restore your subscription:\n\n1. Go to Settings\n2. Tap "Restore Purchases"\n\nYour subscription will be reconnected to your account.',
          style: SeasonsTextStyles.bodySmall.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got it',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.all(SeasonsSpacing.md),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: SeasonsColors.primary, size: 24),
          const SizedBox(height: SeasonsSpacing.sm),
          Text(
            label,
            style: SeasonsTextStyles.body.copyWith(
              color: SeasonsColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: SeasonsTextStyles.caption.copyWith(
              color: SeasonsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class _FaqExpandable extends StatefulWidget {
  final _FaqItem item;

  const _FaqExpandable({required this.item});

  @override
  State<_FaqExpandable> createState() => _FaqExpandableState();
}

class _FaqExpandableState extends State<_FaqExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SeasonsSpacing.sm),
      child: SoftCard(
        borderRadius: SeasonsSpacing.radiusMedium,
        padding: EdgeInsets.zero,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(SeasonsSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: SeasonsTextStyles.body.copyWith(
                        color: SeasonsColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: SeasonsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SeasonsSpacing.md,
                  0,
                  SeasonsSpacing.md,
                  SeasonsSpacing.md,
                ),
                child: Text(
                  widget.item.answer,
                  style: SeasonsTextStyles.bodySmall.copyWith(
                    color: SeasonsColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
