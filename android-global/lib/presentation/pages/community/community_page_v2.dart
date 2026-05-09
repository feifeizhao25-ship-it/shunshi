/// Wellness圈Community页 — 参考UI _2
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

class CommunityPageV2 extends StatelessWidget {
  const CommunityPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Text(AppLocalizations.of(context).t('community_seasons_shunshi'), style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.primary,
                  )),
                  const Spacer(),
                  const Icon(Icons.menu, color: ShunShiColors.textSecondary),
                ]),
              ),
            ),
          ),

          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(AppLocalizations.of(context).t('community_wellness_circle'), style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 32, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.search, color: ShunShiColors.textTertiary, size: 20),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).t('community_search_wellness_content'), style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
                ]),
              ),
            ),
          ),

          // Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                _buildTab('Featured', true),
                const SizedBox(width: 16),
                _buildTab('Posts', false),
                const SizedBox(width: 16),
                _buildTab('Challenges', false),
                const SizedBox(width: 16),
                _buildTab('Food TherapyShare', false),
              ]),
            ),
          ),

          // Post 1 — Food TherapyShare
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(context,
                name: 'Cloud & Water Zen',
                type: 'Qi Deficient',
                content: 'Today is Start of Spring — tried astragalus chicken soup this morning with a few jujubes. Warming and nourishing without being drying, I really do feel more energized.',
                likes: 128, comments: 24,
              ),
            ),
          ),

          // AI指导卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFE4C285), size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).t('community_seasons_ai_guidance'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text(AppLocalizations.of(context).t('community_tip_focus_on_spring_liver_care'), style: TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    '\"Spring wellness focuses on growth. Eat more greens, rise early, walk slowly to nurture your spirit.\"',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _buildHashTag('#Start of Spring'),
                    _buildHashTag('#Soothe Liver Qi'),
                  ]),
                ]),
              ),
            ),
          ),

          // Post 2 — 挑战打卡
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(context,
                name: 'Pine Wind Listening Spring',
                type: 'Yang Deficient',
                badge: Icons.emoji_events,
                badgeText: 'Participated in the "100-Day Wellness Challenge" Day 42',
                content: 'Consistently doing moxibustion at Zusanli each evening — the heaviness in my legs has noticeably disappeared and sleep is much more restful.',
                likes: 352, comments: 89,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // FAB
      floatingActionButton: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: ShunShiColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Text(label, style: TextStyle(
      fontSize: 15,
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      color: active ? ShunShiColors.primary : ShunShiColors.textTertiary,
    ));
  }

  Widget _buildHashTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(tag, style: TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _buildPost(BuildContext context, {
    required String name, required String type, required String content,
    required int likes, required int comments,
    IconData? badge, String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User row
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(
            shape: BoxShape.circle, color: ShunShiColors.primaryContainer,
          ), child: Icon(Icons.person, color: ShunShiColors.primary, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(type, style: TextStyle(fontSize: 10, color: Colors.orange)),
            ),
          ])),
          Icon(Icons.more_horiz, color: ShunShiColors.textTertiary, size: 18),
        ]),

        // Badge
        if (badge != null && badgeText != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(badge, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 6),
            Text(badgeText, style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
        ],

        // Content
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),

        // Actions
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.favorite_border, size: 18, color: ShunShiColors.textTertiary),
          const SizedBox(width: 4),
          Text('$likes', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          const SizedBox(width: 20),
          Icon(Icons.chat_bubble_outline, size: 18, color: ShunShiColors.textTertiary),
          const SizedBox(width: 4),
          Text('$comments', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          const Spacer(),
          Icon(Icons.share, size: 18, color: ShunShiColors.textTertiary),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context).t('share'), style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
        ]),
      ]),
    );
  }
}
