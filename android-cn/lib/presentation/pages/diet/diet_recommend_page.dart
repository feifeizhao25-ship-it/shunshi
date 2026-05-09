/// 饮食推荐页 — 根据体质/节气推荐食疗方案
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/state_view.dart';

class DietRecommendPage extends StatefulWidget {
  final String? constitutionType;
  final String? season;

  const DietRecommendPage({super.key, this.constitutionType, this.season});

  @override
  State<DietRecommendPage> createState() => _DietRecommendPageState();
}

class _DietRecommendPageState extends State<DietRecommendPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _activeFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': '全部', 'icon': Icons.apps},
    {'key': 'diet', 'label': '食疗', 'icon': Icons.restaurant},
    {'key': 'tea', 'label': '药茶', 'icon': Icons.local_cafe},
    {'key': 'recipe', 'label': '食谱', 'icon': Icons.menu_book},
    {'key': 'herb', 'label': '方剂', 'icon': Icons.healing},
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() { _loading = true; });
    try {
      final query = _getQueryForType(widget.constitutionType);
      final params = <String, dynamic>{'q': query, 'top_k': 20};
      if (_activeFilter != 'all') params['content_type'] = _activeFilter;
      final resp = await ApiClient().get(
        '/api/v1/knowledge/search',
        queryParameters: params,
      );
      final data = resp.data;
      if (data != null && data['success'] == true) {
        var results = data['data']['results'] as List<dynamic>;
        if (_activeFilter == 'all') {
          results = results.where((r) =>
            ['diet', 'tea', 'recipe', 'herb'].contains(r['type'])
          ).toList();
        }
        if (mounted) setState(() { _items = results; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _getQueryForType(String? type) {
    switch (type) {
      case 'qixu': return '补气健脾';
      case 'yangxu': return '温阳散寒';
      case 'yinxu': return '滋阴润燥';
      case 'tanshi': return '化痰祛湿';
      case 'shire': return '清热利湿';
      case 'xueyu': return '活血化瘀';
      case 'qiyu': return '疏肝解郁';
      case 'tebing': return '防过敏清淡';
      default: return '养生食疗';
    }
  }

  Future<void> _onFilterChanged(String key) async {
    setState(() => _activeFilter = key);
    await _loadContent();
  }

  List<dynamic> get _filteredItems {
    if (_activeFilter == 'all') return _items;
    return _items.where((i) => i['type'] == _activeFilter).toList();
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'diet': return Icons.restaurant;
      case 'tea': return Icons.local_cafe;
      case 'recipe': return Icons.menu_book;
      case 'herb': return Icons.healing;
      default: return Icons.eco;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'diet': return const Color(0xFF4CAF50);
      case 'tea': return const Color(0xFF8D6E63);
      case 'recipe': return const Color(0xFFFF9800);
      case 'herb': return const Color(0xFF9C27B0);
      default: return ShunShiColors.primary;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'diet': return '食疗';
      case 'tea': return '药茶';
      case 'recipe': return '食谱';
      case 'herb': return '方剂';
      default: return '养生';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    final items = _filteredItems;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('饮食推荐', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final active = _activeFilter == f['key'];
              return ChoiceChip(
                avatar: Icon(f['icon'] as IconData, size: 16, color: active ? Colors.white : ShunShiColors.textSecondary),
                label: Text(f['label'] as String),
                selected: active,
                selectedColor: ShunShiColors.primary,
                labelStyle: TextStyle(color: active ? Colors.white : ShunShiColors.textPrimary, fontSize: 13),
                onSelected: (_) => _onFilterChanged(f['key'] as String),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Content list
        Expanded(
          child: _loading
              ? const LoadingSkeleton(itemCount: 4)
              : _error != null
                  ? ErrorView(message: '加载失败，请重试', onRetry: _loadContent)
                  : items.isEmpty
                      ? const ErrorView(message: '暂无推荐内容', icon: Icons.search_off)
                      : RefreshIndicator(
                      onRefresh: _loadContent,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildItemCard(items[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final type = item['type'] as String?;
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(type), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(_typeLabel(type), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Text('查看', style: TextStyle(fontSize: 12, color: ShunShiColors.primary)),
            GestureDetector(
          onTap: () {
            final id = item['id'];
            if (id != null) context.push('/content-detail', extra: {'contentId': id});
          },
          child: Row(children: [
            Text('查看', style: TextStyle(fontSize: 12, color: ShunShiColors.primary)),
            Icon(Icons.arrow_forward, size: 14, color: ShunShiColors.primary),
          ]),
        ),
          ]),
          const SizedBox(height: 6),
          Text(item['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 4),
          Text(item['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
        ])),
      ]),
    );
  }
}
