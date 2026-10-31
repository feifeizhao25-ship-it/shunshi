/// 养生圈社区页 — 参考UI _2
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class CommunityPageV2 extends StatelessWidget {
  const CommunityPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Text('SEASONS', style: TextStyle(
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
              child: Text('Wellness circle', style: TextStyle(
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
                  Text('Search wellness content...', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
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
                _buildTab('Feed', false),
                const SizedBox(width: 16),
                _buildTab('Challenges', false),
                const SizedBox(width: 16),
                _buildTab('Food therapy sharing', false),
              ]),
            ),
          ),

          // Post 1 — 食疗分享
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(
                name: 'CloudWater',
                type: 'Qi Deficiency',
                content: 'Today is the start of spring. I tried astragalus chicken stew with a few red dates this morning. Warming but not heating — I do feel more energetic.',
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
                    Text('SEASONS AI guidance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text('Suggested focus: soothing the liver in spring', style: TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    '"Spring wellness is about growth. Eat more green vegetables, go to bed a little late, rise early and walk with loose hair so your spirit can grow."',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _buildHashTag('#StartOfSpring'),
                    _buildHashTag('#LiverQi'),
                  ]),
                ]),
              ),
            ),
          ),

          // Post 2 — 挑战打卡
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(
                name: 'PineBreeze',
                type: 'Yang Deficiency',
                badge: Icons.emoji_events,
                badgeText: 'Joined day 42 of the "100-day wellness challenge"',
                content: 'Moxibustion on Zusanli every evening — the heaviness in my legs has clearly gone and I sleep much better.',
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

  Widget _buildPost({
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
          Text('Share', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
        ]),
      ]),
    );
  }
}
