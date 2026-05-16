/// 养生圈社区页 — 接 API
/// GET /api/v1/community/posts → 帖子列表
/// POST /api/v1/community/posts → 发帖
library;

import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class CommunityPageV2 extends StatefulWidget {
  const CommunityPageV2({super.key});

  @override
  State<CommunityPageV2> createState() => _CommunityPageV2State();
}

class _CommunityPageV2State extends State<CommunityPageV2> with SingleTickerProviderStateMixin {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''), connectTimeout: const Duration(seconds: 8)));
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  int _currentTab = 0;
  final _tabs = ['精选', '动态', '挑战打卡', '食疗分享'];

  // Seed data for when API is empty
  static final _seedPosts = [
    {'user_name': '云水禅心', 'user_type': '气虚质', 'content': '今日立春，晨起尝试了黄芪炖鸡，加入了几枚大枣。温补而不燥，感觉精神确实好多了。', 'like_count': 128, 'comment_count': 24, 'category': '食疗分享'},
    {'user_name': '松风听泉', 'user_type': '阳虚质', 'content': '坚持每天晚间艾灸足三里，感觉双腿的沉重感明显消失了，睡眠也踏实了很多。', 'like_count': 352, 'comment_count': 89, 'category': '挑战打卡'},
    {'user_name': '清风明月', 'user_type': '平和质', 'content': '分享我的八段锦练习心得：第一式两手托天理三焦，吸气时想象清气从脚底升到头顶，呼气时浊气下降。坚持一个月，肩颈僵硬好多了。', 'like_count': 256, 'comment_count': 67, 'category': '动态'},
    {'user_name': '竹影横斜', 'user_type': '阴虚质', 'content': '谷雨时节，泡了一壶菊花枸杞茶，清肝明目。最近熬夜多，这杯茶让眼睛舒服了不少。推荐阴虚体质的朋友试试。', 'like_count': 89, 'comment_count': 15, 'category': '食疗分享'},
    {'user_name': '荷塘月色', 'user_type': '气郁质', 'content': '每天早起散步30分钟，配合玫瑰花茶疏肝解郁。半个月下来，胸闷的感觉少了很多，心情也开朗了。', 'like_count': 198, 'comment_count': 42, 'category': '挑战打卡'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final res = await _dio.get('/api/v1/community/posts', queryParameters: {'limit': 20, 'offset': 0});
      final data = res.data;
      if (data is Map && data['posts'] is List) {
        _posts = (data['posts'] as List).cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        _posts = (data['data'] as List).cast<Map<String, dynamic>>();
      } else if (data is List) {
        _posts = data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    // Use seed data if API returns empty
    if (_posts.isEmpty) {
      _posts = _seedPosts;
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_currentTab == 0) return _posts; // 精选 = all
    final tab = _tabs[_currentTab];
    return _posts.where((p) => (p['category'] ?? '') == tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final posts = _filteredPosts;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              Text('顺时 ShunShi', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.primary)),
              const Spacer(),
              const Icon(Icons.menu, color: ShunShiColors.textSecondary),
            ]),
          ))),

          // Title
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text('养生圈', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 32, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
          )),

          // Tabs
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (int i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => _currentTab = i),
                  child: _buildTab(_tabs[i], i == _currentTab),
                ),
              ],
            ])),
          )),

          // Loading
          if (_loading) const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: ShunShiColors.primary)),
          )),

          // Posts
          if (!_loading && posts.isEmpty) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(40), child: Center(child: Text('暂无帖子', style: TextStyle(color: ShunShiColors.textTertiary))),
          )),

          for (int i = 0; i < posts.length; i++) ...[
            // AI card after first post
            if (i == 1) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildAICard(),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(24, i == 0 ? 16 : 12, 24, 0),
              child: _buildPost(posts[i]),
            )),
          ],

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
        child: IconButton(onPressed: () => _showPostDialog(context), icon: const Icon(Icons.add, color: Colors.white, size: 28)),
      ),
    );
  }

  Widget _buildTab(String label, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: active ? ShunShiColors.primary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? ShunShiColors.primary : ShunShiColors.textTertiary)),
  );

  Widget _buildAICard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFE4C285), size: 18),
        const SizedBox(width: 8),
        const Text('顺时 AI 指导', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const Spacer(),
        Text('建议关注：${DateTime.now().month <= 5 ? "春季疏肝" : "四季养生"}', style: const TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
      ]),
      const SizedBox(height: 12),
      const Text('"顺应天时，调和身心。分享你的养生日常，让更多人受益。"', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6)),
    ]),
  );

  Widget _buildPost(Map<String, dynamic> post) {
    final name = post['user_name'] ?? post['author'] ?? '匿名用户';
    final type = post['user_type'] ?? post['tag'] ?? '';
    final content = post['content'] ?? post['body'] ?? '';
    final likes = (post['like_count'] ?? post['likes'] ?? 0) is int ? post['like_count'] ?? post['likes'] ?? 0 : 0;
    final comments = (post['comment_count'] ?? post['comments'] ?? 0) is int ? post['comment_count'] ?? post['comments'] ?? 0 : 0;
    final badge = post['badge_text'] ?? post['achievement'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primaryContainer),
            child: Icon(Icons.person, color: ShunShiColors.primary, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            if (type.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(type, style: TextStyle(fontSize: 10, color: Colors.orange)),
            ),
          ])),
          Icon(Icons.more_horiz, color: ShunShiColors.textTertiary, size: 18),
        ]),
        if (badge != null && badge.toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16), const SizedBox(width: 6), Text(badge.toString(), style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, fontWeight: FontWeight.w500))]),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showPostDetail(context, post),
          child: Text(content, style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          GestureDetector(
            onTap: () => _showPostDetail(context, post),
            child: Icon(Icons.favorite_border, size: 18, color: ShunShiColors.textTertiary),
          ), const SizedBox(width: 4),
          Text('$likes', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)), const SizedBox(width: 20),
          GestureDetector(
            onTap: () => _showPostDetail(context, post),
            child: Icon(Icons.chat_bubble_outline, size: 18, color: ShunShiColors.textTertiary),
          ), const SizedBox(width: 4),
          Text('$comments', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)), const Spacer(),
          GestureDetector(
            onTap: () => _sharePost(post),
            child: Row(children: [Icon(Icons.share, size: 18, color: ShunShiColors.textTertiary), const SizedBox(width: 4), const Text('分享', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary))]),
          ),
        ]),
      ]),
    );
  }

  void _showPostDetail(BuildContext context, Map<String, dynamic> post) {
    final name = post['user_name'] ?? post['author'] ?? '匿名用户';
    final type = post['user_type'] ?? post['tag'] ?? '';
    final content = post['content'] ?? post['body'] ?? '';
    final likes = (post['like_count'] ?? post['likes'] ?? 0) is int ? post['like_count'] ?? post['likes'] ?? 0 : 0;
    final comments = (post['comment_count'] ?? post['comments'] ?? 0) is int ? post['comment_count'] ?? post['comments'] ?? 0 : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShunShiColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primaryContainer), child: Icon(Icons.person, color: ShunShiColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                if (type.isNotEmpty) Text(type, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
              ])),
            ]),
            const SizedBox(height: 16),
            Text(content, style: TextStyle(fontSize: 16, color: ShunShiColors.textSecondary, height: 1.8)),
            const SizedBox(height: 20),
            Divider(color: ShunShiColors.borderGhost),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.favorite_border, size: 20, color: ShunShiColors.primary), const SizedBox(width: 6), Text('$likes 赞', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
              const SizedBox(width: 24),
              Icon(Icons.chat_bubble_outline, size: 20, color: ShunShiColors.primary), const SizedBox(width: 6), Text('$comments 评论', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    final content = post['content'] ?? '';
    final name = post['user_name'] ?? '匿名';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('分享 $name 的动态：${content.length > 20 ? content.substring(0, 20) + '…' : content}')),
    );
  }

  void _showPostDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('发帖', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: '分享你的养生日常...', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          final text = controller.text.trim();
          if (text.isEmpty) return;
          try {
            await _dio.post('/api/v1/community/posts', data: {'content': text, 'user_id': 'guest', 'category': '动态'});
          } catch (_) {}
          if (mounted) {
            Navigator.pop(ctx);
            _loadPosts();
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white), child: const Text('发布')),
      ],
    ));
  }
}
