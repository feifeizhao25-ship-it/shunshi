/// 全局搜索页 — 食谱/穴位/茶饮/文章
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/theme.dart';

class _TypeFilter {
  final String label;
  final String? value;
  const _TypeFilter(this.label, this.value);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''), connectTimeout: const Duration(seconds: 8)));
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _query = '';
  String? _activeType;

  static const _types = <_TypeFilter>[
    _TypeFilter('全部', null),
    _TypeFilter('食疗', 'food_therapy'),
    _TypeFilter('茶饮', 'tea'),
    _TypeFilter('穴位', 'acupoint'),
    _TypeFilter('运动', 'exercise'),
    _TypeFilter('冥想', 'meditation'),
  ];

  static const _hotTags = ['黄芪', '春季养肝', '足三里', '菊花茶', '八段锦', '失眠', '湿气', '脾胃'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _query = ''; _results = []; _loading = false; });
      return;
    }
    setState(() { _query = q; _loading = true; });
    try {
      final params = <String, dynamic>{'q': q, 'limit': 20};
      if (_activeType != null) params['type'] = _activeType!;
      final res = await _dio.get('/api/v1/contents', queryParameters: params);
      final data = res.data;
      List items = [];
      if (data is Map) {
        final inner = data['data'];
        if (inner is Map) {
          items = (inner['items'] ?? []) as List;
        } else if (inner is List) {
          items = inner;
        } else {
          items = (data['items'] ?? []) as List;
        }
      } else if (data is List) {
        items = data;
      }
      _results = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _results = [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_query.isNotEmpty) _buildTypeFilters(),
            Expanded(
              child: _query.isEmpty ? _buildHotSearch() : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ShunShiColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: ShunShiColors.textTertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '搜索养生内容...',
                        hintStyle: TextStyle(color: ShunShiColors.textTertiary),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _search,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: ShunShiColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _types.map((t) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t.label),
              selected: _activeType == t.value,
              onSelected: (_) {
                setState(() => _activeType = _activeType == t.value ? null : t.value);
                _search(_query);
              },
              selectedColor: ShunShiColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 13,
                color: _activeType == t.value ? ShunShiColors.primary : ShunShiColors.textSecondary,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildHotSearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('热门搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _hotTags.map((t) => GestureDetector(
              onTap: () { _controller.text = t; _search(t); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Text(t, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 32),
          Text('按类型浏览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _browseIcon(Icons.restaurant, '食疗', 'food_therapy'),
              _browseIcon(Icons.local_cafe, '茶饮', 'tea'),
              _browseIcon(Icons.accessibility_new, '穴位', 'acupoint'),
              _browseIcon(Icons.self_improvement, '运动', 'exercise'),
              _browseIcon(Icons.spa, '冥想', 'meditation'),
              _browseIcon(Icons.nights_stay, '睡眠', 'sleep'),
              _browseIcon(Icons.menu_book, '文章', 'article'),
              _browseIcon(Icons.more_horiz, '更多', null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _browseIcon(IconData icon, String label, String? type) {
    return GestureDetector(
      onTap: () {
        if (type != null) {
          setState(() => _activeType = type);
          _controller.text = label;
          _search(label);
        }
      },
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: ShunShiColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ShunShiColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: ShunShiColors.primary));
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: ShunShiColors.textTertiary),
            const SizedBox(height: 12),
            Text('未找到相关内容', style: TextStyle(color: ShunShiColors.textTertiary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (_, i) => _resultCard(_results[i]),
    );
  }

  Widget _resultCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final desc = item['description'] ?? '';
    final type = item['type'] ?? '';
    final iconMap = {
      'food_therapy': Icons.restaurant,
      'tea': Icons.local_cafe,
      'acupoint': Icons.accessibility_new,
      'exercise': Icons.self_improvement,
      'meditation': Icons.spa,
    };
    final icon = iconMap[type] ?? Icons.article;

    return GestureDetector(
      onTap: () {
        final id = item['id']?.toString();
        if (id != null) Navigator.pushNamed(context, '/content/$id');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ShunShiColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (type.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(type, style: TextStyle(fontSize: 10, color: ShunShiColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
