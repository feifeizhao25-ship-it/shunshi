import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

/// 社区页 — Wellness Circle
///
/// 参考: _2/code.html — 搜索 + 筛选Tab + Feed流 + AIGuide卡片 + FAB
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedFilter = 0;
  static const _filters = ['Featured', 'Activity', 'Challenges', 'Food Tips'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMUNITY',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.sansFamily,
                                fontSize: 13,
                                color: ShunShiColors.textTertiary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Wellness Circle',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.serifFamily,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: ShunShiColors.primary,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ShunShiColors.surfaceContainerLow,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: ShunShiColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: ShunShiColors.textTertiary, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search for wellness inspiration...',
                                hintStyle: TextStyle(
                                  color: ShunShiColors.textTertiary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Filter Tabs
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 24),
                        itemBuilder: (_, i) {
                          final isActive = i == _selectedFilter;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = i),
                            child: Column(
                              children: [
                                Text(
                                  _filters[i],
                                  style: TextStyle(
                                    fontFamily: ShunShiTypography.sansFamily,
                                    fontSize: 14,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isActive ? ShunShiColors.primary : ShunShiColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: isActive ? ShunShiColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Feed Items ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // AI Insight Card (Glassmorphism)
                  _GlassAIInsightCard(),
                  const SizedBox(height: 24),
                  // Placeholder posts
                  _FeedPostCard(
                    author: 'Nature Seeker',
                    badge: 'Balanced',
                    content: 'Today is the Start of Spring，Started the day with a nourishing herbal soup，Added some red dates for extra warmth。Warming but not drying，Feeling much more energized。',
                    likes: 128,
                    comments: 24,
                  ),
                  const SizedBox(height: 24),
                  _FeedPostCard(
                    author: 'Mountain Breeze',
                    badge: 'Yang Type',
                    content: 'Consistent evening moxibustion practice，The heaviness in my legs has noticeably faded，Sleep quality has greatly improved。',
                    likes: 352,
                    comments: 89,
                    isChallenge: true,
                    challengeDay: 42,
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: ShunShiColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ShunShiColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── AI Insight Glassmorphism Card ──

class _GlassAIInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ShunShiColors.surfaceContainerLow.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: ShunShiColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: ShunShiColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEASONS AI Guide',
                        style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ShunShiColors.primary,
                        ),
                      ),
                      Text(
                        'Suggested Focus：Spring Liver Support',
                        style: TextStyle(
                          fontFamily: ShunShiTypography.sansFamily,
                          fontSize: 12,
                          color: ShunShiColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '"Spring wellness focuses on growth and renewal. Eat more green vegetables, rise early, and move gently to cultivate vitality."',
                style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 18,
                  color: ShunShiColors.primary,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _TagChip('#Spring Begins'),
                  const SizedBox(width: 8),
                  _TagChip('#Liver & Energy Flow'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: ShunShiTypography.sansFamily,
          fontSize: 12,
          color: ShunShiColors.primary,
        ),
      ),
    );
  }
}

// ── Feed Post Card ──

class _FeedPostCard extends StatelessWidget {
  final String author;
  final String badge;
  final String content;
  final int likes;
  final int comments;
  final bool isChallenge;
  final int? challengeDay;

  const _FeedPostCard({
    required this.author,
    required this.badge,
    required this.content,
    required this.likes,
    required this.comments,
    this.isChallenge = false,
    this.challengeDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ShunShiColors.surfaceContainerLow,
                ),
                child: const Icon(Icons.person, color: ShunShiColors.textTertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ShunShiColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 10, color: ShunShiColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: ShunShiColors.textTertiary),
            ],
          ),
          const SizedBox(height: 16),
          // Challenge badge
          if (isChallenge && challengeDay != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ShunShiColors.goldLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: ShunShiColors.secondary, width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: ShunShiColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Joined「100-Day Wellness Challenge」',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ShunShiColors.secondary,
                      ),
                    ),
                  ),
                  Text(
                    'Day $challengeDay',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ShunShiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Content
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: ShunShiColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              _ActionButton(Icons.favorite_border, likes.toString()),
              const SizedBox(width: 24),
              _ActionButton(Icons.chat_bubble_outline, comments.toString()),
              const SizedBox(width: 24),
              _ActionButton(Icons.share_outlined, 'Share'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionButton(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ShunShiColors.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 13,
            color: ShunShiColors.secondary,
          ),
        ),
      ],
    );
  }
}
