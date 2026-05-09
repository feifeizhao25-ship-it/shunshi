// ignore_for_file: unused_local_variable
/// 通用内容详情页 — 支持 diet/tea/recipe/herb/exercise 等所有内容类型
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/state_view.dart';
import '../../widgets/acupoint_timer_sheet.dart';

class ContentDetailPage extends StatefulWidget {
  final String contentId;
  const ContentDetailPage({super.key, required this.contentId});

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _isFavorited = false;
  static const _userId = 'guest';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient().get('/api/v1/contents/${widget.contentId}');
      final data = resp.data;
      if (data != null && data['success'] == true) {
        if (mounted) setState(() { _data = data['data']; _loading = false; });
      } else {
        if (mounted) setState(() { _loading = false; _error = '内容不存在'; });
      }
      // Check favorite status
      try {
        final favResp = await ApiClient().get('/api/v1/favorites/check',
          queryParameters: {'user_id': _userId, 'content_id': widget.contentId});
        if (favResp.data?['success'] == true) {
          if (mounted) setState(() => _isFavorited = favResp.data['data']['is_favorited'] ?? false);
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '网络错误，请重试'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : null),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareContent(),
          ),
        ],
        title: Text(_data?['title'] ?? '详情',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StateView<Map<String, dynamic>>(
        loading: _loading,
        error: _error,
        data: _data,
        onRetry: _loadData,
        loadingWidget: const LoadingSkeleton(itemCount: 1),
        builder: (data) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header card
            _buildHeader(data),
            const SizedBox(height: 20),

            // Description
            if (data['description'] != null) ...[
              _sectionTitle('概述'),
              const SizedBox(height: 8),
              Text(data['description'].toString(),
                style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
              const SizedBox(height: 20),
            ],

            // Location (for acupoints)
            if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
              _sectionTitle('定位'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.location_on, color: ShunShiColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(data['location'].toString(), style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, height: 1.6))),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Method
            if (data['method'] != null && data['method'].toString().isNotEmpty) ...[
              _sectionTitle('方法'),
              const SizedBox(height: 8),
              Text(data['method'].toString(), style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
              const SizedBox(height: 20),
            ],

            // Steps
            if (data['steps'] != null) ...[
              _sectionTitle('步骤'),
              const SizedBox(height: 8),
              _buildSteps(data['steps']),
              const SizedBox(height: 20),
            ],

            // Timer button for acupoints
            if (data['type'] == 'acupoint' || data['type'] == 'acupressure') ...[
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                onPressed: () => _showTimer(context, data['title'].toString()),
                icon: Icon(Icons.timer, size: 20),
                label: Text('开始按摩计时'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              )),
              const SizedBox(height: 20),
            ],

            // Content (for items with long text content)
            if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
              _sectionTitle('详细内容'),
              const SizedBox(height: 8),
              Text(data['content'].toString(),
                style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
              const SizedBox(height: 20),
            ],

            // Caution
            if (data['caution'] != null && data['caution'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(data['caution'].toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF795548), height: 1.6))),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Source
            if (data['source_classic'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.menu_book, size: 16, color: ShunShiColors.textTertiary),
                  const SizedBox(width: 8),
                  Text('出处：${data['source_classic']}',
                    style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, fontStyle: FontStyle.italic)),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Tags
            if (data['tags'] != null) ...[
              Wrap(spacing: 8, runSpacing: 8,
                children: (data['tags'] as List).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t.toString(), style: TextStyle(fontSize: 12, color: ShunShiColors.primary)),
                )).toList()),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final typeColor = _typeColor(data['type']);
    final typeLabel = _typeLabel(data['type']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [typeColor.withOpacity(0.85), typeColor]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(typeLabel, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 12),
        // Subtitle
        if (data['subtitle'] != null)
          Text(data['subtitle'].toString(), style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 6),
        // Title
        Text(data['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        // Meta row
        const SizedBox(height: 12),
        Row(children: [
          if (data['best_time'] != null) ...[
            Icon(Icons.access_time, color: Colors.white.withOpacity(0.7), size: 14),
            const SizedBox(width: 4),
            Text(data['best_time'].toString(), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
            const SizedBox(width: 16),
          ],
          if (data['duration_minutes'] != null && data['duration_minutes'] > 0) ...[
            Icon(Icons.timer, color: Colors.white.withOpacity(0.7), size: 14),
            const SizedBox(width: 4),
            Text('${data['duration_minutes']}分钟', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ],
          if (data['season'] != null) ...[
            const SizedBox(width: 16),
            Icon(Icons.eco, color: Colors.white.withOpacity(0.7), size: 14),
            const SizedBox(width: 4),
            Text(data['season'].toString(), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ],
        ]),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary));
  }

  Widget _buildSteps(dynamic steps) {
    List<String> stepList;
    if (steps is List) {
      stepList = steps.map((s) => s.toString()).toList();
    } else if (steps is String) {
      stepList = [steps];
    } else {
      return const SizedBox.shrink();
    }
    return Column(children: stepList.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: ShunShiColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('${e.key + 1}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(e.value,
            style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6))),
        ]),
      );
    }).toList());
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'diet': return const Color(0xFF4CAF50);
      case 'tea': return const Color(0xFF8D6E63);
      case 'recipe': return const Color(0xFFFF9800);
      case 'herb': return const Color(0xFF9C27B0);
      case 'meridian': return ShunShiColors.primary;
      case 'exercise': return const Color(0xFF2196F3);
      case 'acupoint': return const Color(0xFFE91E63);
      default: return ShunShiColors.primary;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'diet': return '食疗';
      case 'tea': return '药茶';
      case 'recipe': return '食谱';
      case 'herb': return '方剂';
      case 'meridian': return '经络';
      case 'exercise': return '导引';
      case 'acupoint': return '穴位';
      case 'emotion': return '情志';
      case 'sleep': return '安神';
      case 'constitution': return '体质';
      default: return '养生';
    }
  }

  Future<void> _toggleFavorite() async {
    final wasFavorited = _isFavorited;
    setState(() => _isFavorited = !_isFavorited);
    try {
      if (wasFavorited) {
        await ApiClient().delete('/api/v1/favorites/${widget.contentId}?user_id=$_userId');
      } else {
        await ApiClient().post('/api/v1/favorites', data: {
          'user_id': _userId,
          'content_id': widget.contentId,
          'content_type': _data?['type'] ?? 'unknown',
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorited = wasFavorited);
    }
  }

  void _showTimer(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcupointTimerSheet(acupointName: name),
    );
  }

  void _shareContent() {
    final title = _data?['title'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $title'), duration: const Duration(seconds: 2)),
    );
  }
}
