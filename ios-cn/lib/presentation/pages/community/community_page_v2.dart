/// 养生圈社区页 — 参考UI _2
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';

class CommunityPageV2 extends StatelessWidget {
  const CommunityPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  Text('顺时', style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary(context),
                  )),
                  const Spacer(),
                  Icon(Icons.menu, color: AppColors.textSecondary(context)),
                ]),
              ),
            ),
          ),

          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('养生圈', style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
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
                  color: AppColors.surfaceContainerLow(context), borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.search, color: AppColors.textTertiary(context), size: 20),
                  const SizedBox(width: 8),
                  Text('搜索养生内容...', style: TextStyle(fontSize: 14, color: AppColors.textTertiary(context))),
                ]),
              ),
            ),
          ),

          // Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                _buildTab(context, '精选', true),
                const SizedBox(width: 16),
                _buildTab(context, '动态', false),
                const SizedBox(width: 16),
                _buildTab(context, '挑战打卡', false),
                const SizedBox(width: 16),
                _buildTab(context, '食疗分享', false),
              ]),
            ),
          ),

          // Post 1 — 食疗分享
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(context: context, 
                name: '云水禅心',
                type: '气虚质',
                content: '今日立春，晨起尝试了黄芪炖鸡，加入了几枚大枣。温补而不燥，感觉精神确实好多了。',
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
                    Text('顺时 AI 指导', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text('建议关注：春季疏肝', style: TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    '"春季养生，重在生发。建议多食青绿色蔬菜，晚睡早起，披发缓行，以使志生。"',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _buildHashTag('#立春'),
                    _buildHashTag('#疏肝理气'),
                  ]),
                ]),
              ),
            ),
          ),

          // Post 2 — 挑战打卡
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildPost(context: context, 
                name: '松风听泉',
                type: '阳虚质',
                badge: Icons.emoji_events,
                badgeText: '参与了「百日养生挑战」第 42 天',
                content: '坚持每天晚间艾灸足三里，感觉双腿的沉重感明显消失了，睡眠也踏实了很多。',
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
          boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, bool active) {
    return Text(label, style: TextStyle(
      fontSize: 15,
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      color: active ? AppColors.primary(context) : AppColors.textTertiary(context),
    ));
  }

  Widget _buildHashTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(tag, style: TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _buildPost({required BuildContext context, 
    required String name, required String type, required String content,
    required int likes, required int comments,
    IconData? badge, String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User row
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(
            shape: BoxShape.circle, color: ShunShiColors.primaryContainer,
          ), child: Icon(Icons.person, color: AppColors.primary(context), size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(type, style: TextStyle(fontSize: 10, color: Colors.orange)),
            ),
          ])),
          Icon(Icons.more_horiz, color: AppColors.textTertiary(context), size: 18),
        ]),

        // Badge
        if (badge != null && badgeText != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(badge, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 6),
            Text(badgeText, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
          ]),
        ],

        // Content
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.6)),

        // Actions
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.favorite_border, size: 18, color: AppColors.textTertiary(context)),
          const SizedBox(width: 4),
          Text('$likes', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
          const SizedBox(width: 20),
          Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textTertiary(context)),
          const SizedBox(width: 4),
          Text('$comments', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
          const Spacer(),
          Icon(Icons.share, size: 18, color: AppColors.textTertiary(context)),
          const SizedBox(width: 4),
          Text('分享', style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
        ]),
      ]),
    );
  }
}
