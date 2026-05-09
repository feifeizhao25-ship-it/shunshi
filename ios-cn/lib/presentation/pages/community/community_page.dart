import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedTab = 0;
  final _tabs = ['精选', '动态', '挑战打卡', '食疗分享'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // 社区头图
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Container(
                    width: double.infinity, height: 120,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: const DecorationImage(image: AssetImage('assets/images/ref_02.jpg'), fit: BoxFit.cover)),
                  )),
                  _buildAiInsightCard(),
                  const SizedBox(height: 12),
                  ..._buildFeedItems(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ShunShiColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发帖功能开发中'), duration: Duration(seconds: 1)));
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            '养生圈',
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ShunShiColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: ShunShiColors.textSecondary),
            onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('搜索功能开发中'), duration: Duration(seconds: 1))); },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selectedTab;
          return ChoiceChip(
            label: Text(_tabs[i]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedTab = i),
            backgroundColor: ShunShiColors.surface,
            selectedColor: ShunShiColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : ShunShiColors.textSecondary,
              fontSize: 14,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ShunShiColors.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '今日养生洞察',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '今日清明节气，宜食青团、荠菜。肝气旺盛，宜疏肝理气，推荐饮用菊花枸杞茶，配合深呼吸放松身心。',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedItems() {
    return [
      _FeedCard(
        avatar: Icons.person,
        name: '静水流深',
        tag: '气虚质',
        content: '清明踏青归来，煮了一壶玫瑰花茶，心情格外舒畅。分享给大家我的养生茶饮搭配 🌸',
        imageCount: 2,
        likes: 42,
        comments: 8,
      ),
      _FeedCard(
        avatar: Icons.person_outline,
        name: '山水之间',
        tag: '平和质',
        content: '坚持晨练太极第30天！身体明显感觉轻盈了很多，分享我的经验给各位养生圈的朋友们。',
        imageCount: 0,
        likes: 128,
        comments: 23,
      ),
      _FeedCard(
        avatar: Icons.face,
        name: '薄荷微凉',
        tag: '湿热质',
        content: '自制了清热祛湿的薏仁红豆汤，适合这个季节饮用。详细做法见图。',
        imageCount: 3,
        likes: 67,
        comments: 15,
      ),
    ].map((card) => _buildFeedCard(card)).toList();
  }

  Widget _buildFeedCard(_FeedCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ShunShiColors.surface,
                  child: Icon(card.avatar, size: 20, color: ShunShiColors.primary),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: ShunShiColors.textPrimary)),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: ShunShiColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(card.tag, style: TextStyle(color: ShunShiColors.secondary, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(card.content, style: TextStyle(fontSize: 14, height: 1.6, color: ShunShiColors.textPrimary)),
            if (card.imageCount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  card.imageCount > 3 ? 3 : card.imageCount,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < (card.imageCount > 3 ? 2 : card.imageCount - 1) ? 6 : 0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ShunShiColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, color: ShunShiColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _actionChip(Icons.favorite_border, '${card.likes}', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已点赞'), duration: Duration(seconds: 1)));
                }),
                const SizedBox(width: 20),
                _actionChip(Icons.chat_bubble_outline, '${card.comments}', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论功能开发中'), duration: Duration(seconds: 1)));
                }),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined, size: 18, color: ShunShiColors.textTertiary),
                  onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制分享链接'), duration: Duration(seconds: 1))); },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ShunShiColors.textTertiary),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FeedCard {
  final IconData avatar;
  final String name;
  final String tag;
  final String content;
  final int imageCount;
  final int likes;
  final int comments;

  const _FeedCard({
    required this.avatar,
    required this.name,
    required this.tag,
    required this.content,
    required this.imageCount,
    required this.likes,
    required this.comments,
  });
}
