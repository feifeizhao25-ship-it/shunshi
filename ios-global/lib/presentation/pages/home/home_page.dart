// Seasons Home Page — Global Version
// Design: Maximum whitespace, large type, low density

import 'package:seasons/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: SeasonsColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Greeting ──
              _buildGreeting(context),
              const SizedBox(height: 36),

              // ── Divider ──
              _buildDivider(),
              const SizedBox(height: 48),

              // ── Daily Insight — larger text, fewer words ──
              _buildDailyInsight(context, homeState),
              const SizedBox(height: 56),

              // ── Suggestion Cards — minimal: icon + one line ──
              _buildSuggestions(context, homeState),
              const SizedBox(height: 48),

              // ── AI Entry ──
              _buildAIEntry(context),
              const SizedBox(height: 40),

              // ── Season Card ──
              _buildSeasonCard(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Greeting — "Good morning, feifei"
  // ──────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) {
      greeting = 'Good night';
    } else if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$greeting, feifei',
        style: SeasonsTypography.headlineLarge.copyWith(
          color: SeasonsColors.textPrimary,
          fontWeight: FontWeight.w300,
          height: 1.3,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Divider
  // ──────────────────────────────────────────────

  Widget _buildDivider() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 32,
        height: 2,
        decoration: BoxDecoration(
          color: SeasonsColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Daily Insight — 24sp, even more minimal
  // ──────────────────────────────────────────────

  Widget _buildDailyInsight(BuildContext context, dynamic homeState) {
    final insight = homeState.dailyInsight?.text ?? 'Take it slow today';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        insight,
        textAlign: TextAlign.center,
        style: SeasonsTypography.headlineSmall.copyWith(
          color: SeasonsColors.textSecondary,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Suggestion Cards — icon + one sentence
  // ──────────────────────────────────────────────

  Widget _buildSuggestions(BuildContext context, dynamic homeState) {
    final suggestions = [
      _MinimalSuggestion(icon: '🌬️', text: 'Breathe\n5 min'),
      _MinimalSuggestion(icon: '🍵', text: 'Try herbal\ntea today'),
      _MinimalSuggestion(icon: '🧘', text: 'Gentle\nstretch'),
    ];

    return Row(
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == suggestions.length - 1 ? 0 : 8,
            ),
            child: SoftCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              onTap: () {
                // Navigate to detail or expand
              },
              child: Column(
                children: [
                  Text(item.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    item.text,
                    textAlign: TextAlign.center,
                    style: SeasonsTypography.bodySmall.copyWith(
                      color: SeasonsColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  // AI Entry
  // ──────────────────────────────────────────────

  Widget _buildAIEntry(BuildContext context) {
    return SoftCard(
      onTap: () => context.go('/chat'),
      child: Row(
        children: [
          Text('💬', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Talk to your companion',
              style: SeasonsTypography.bodyLarge.copyWith(
                color: SeasonsColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: SeasonsColors.textTertiary,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Season Card (replaces Solar Term)
  // ──────────────────────────────────────────────

  Widget _buildSeasonCard(BuildContext context) {
    return SoftCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🌸', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Early Spring',
                style: SeasonsTypography.titleMedium.copyWith(
                  color: SeasonsColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Time for renewal and gentle movement',
            style: SeasonsTypography.bodySmall.copyWith(
              color: SeasonsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalSuggestion {
  final String icon;
  final String text;
  const _MinimalSuggestion({required this.icon, required this.text});
}
