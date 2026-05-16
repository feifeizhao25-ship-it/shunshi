import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';

/// 全局搜索页 — 搜索知识库内容
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _selectedType;

  static const _types = [
    ('全部', null),
    ('饮食', 'diet'),
    ('茶饮', 'tea'),
    ('运动', 'exercise'),
    ('药膳', 'recipe'),
    ('经络', 'meridian'),
    ('穴位', 'acupoint'),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await ApiClient().get(
        '/api/v1/contents/search',
        queryParameters: {
          'q': query,
          if (_selectedType != null) 'content_type': _selectedType,
        },
      );
      final data = resp.data;
      if (data is Map && data['data'] is Map) {
        final items = data['data']['items'];
        if (items is List) {
          setState(() => _results = items.cast<Map<String, dynamic>>());
        }
      } else if (data is Map && data['results'] is List) {
        setState(() => _results = (data['results'] as List).cast<Map<String, dynamic>>());
      } else if (data is List) {
        setState(() => _results = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: ShunShiColors.surfaceContainerLowest,
        elevation: 0,
        title: _buildSearchField(),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildTypeFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmpty()
                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: TextStyle(fontSize: 16, color: ShunShiColors.textPrimary),
      decoration: InputDecoration(
        hintText: '搜索养生知识...',
        hintStyle: TextStyle(color: ShunShiColors.textTertiary),
        border: InputBorder.none,
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: ShunShiColors.textTertiary),
                onPressed: () {
                  _controller.clear();
                  setState(() => _results = []);
                },
              )
            : null,
      ),
      onSubmitted: _search,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _types.map((t) {
          final selected = _selectedType == t.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t.$1),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedType = selected ? null : t.$2);
                if (_controller.text.isNotEmpty) _search(_controller.text);
              },
              backgroundColor: ShunShiColors.surfaceContainerLowest,
              selectedColor: ShunShiColors.primary.withValues(alpha: 0.15),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    final hotTerms = ['枸杞', '失眠', '疏肝', '脾胃', '八段锦', '祛湿', '安神', '养肝'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('热门搜索', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotTerms.map((term) => GestureDetector(
              onTap: () { _controller.text = term; _search(term); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ShunShiColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(term, style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildResultCard(_results[i]),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? '';
    final desc = item['description']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final id = item['id']?.toString();

    return GestureDetector(
      onTap: () {
        if (id != null) {
          context.push('/content-detail', extra: {'contentId': id});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeChip(type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: ShunShiColors.textPrimary,
                  )),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final colors = {
      'diet': Colors.green, 'tea': Color(0xFF8D6E63), 'exercise': Colors.blue,
      'recipe': Colors.orange, 'herb': Colors.purple, 'meridian': ShunShiColors.primary,
      'acupoint': Colors.pink, 'acupressure': Colors.pink,
    };
    final labels = {
      'diet': '饮食', 'tea': '茶饮', 'exercise': '运动',
      'recipe': '药膳', 'herb': '草药', 'meridian': '经络',
      'acupoint': '穴位', 'acupressure': '穴位',
    };
    final color = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(labels[type] ?? type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
