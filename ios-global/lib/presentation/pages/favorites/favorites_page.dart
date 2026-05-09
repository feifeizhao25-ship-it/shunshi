/// 收藏列表页
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/state_view.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient().get('/api/v1/favorites',
        queryParameters: {'user_id': 'guest', 'limit': 50});
      if (resp.data?['success'] == true) {
        final items = resp.data['data']['items'] as List<dynamic>? ?? [];
        if (mounted) setState(() { _items = items; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '加载失败'; });
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'diet': return Icons.restaurant;
      case 'tea': return Icons.local_cafe;
      case 'recipe': return Icons.menu_book;
      case 'herb': return Icons.healing;
      case 'meridian': return Icons.architecture;
      case 'exercise': return Icons.self_improvement;
      default: return Icons.eco;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'diet': return const Color(0xFF4CAF50);
      case 'tea': return const Color(0xFF8D6E63);
      case 'recipe': return const Color(0xFFFF9800);
      case 'herb': return const Color(0xFF9C27B0);
      case 'meridian': return ShunShiColors.primary;
      case 'exercise': return const Color(0xFF2196F3);
      default: return ShunShiColors.primary;
    }
  }

  String _typeLabel(String? type) {
    const labels = {'diet': '食疗', 'tea': '药茶', 'recipe': '食谱', 'herb': '方剂', 'meridian': '经络', 'exercise': '导引', 'acupoint': '穴位', 'sleep': '安神', 'emotion': '情志'};
    return labels[type] ?? '养生';
  }

  Future<void> _removeFavorite(int index) async {
    final item = _items[index];
    final contentId = item['content_id'];
    setState(() => _items.removeAt(index));
    try {
      await ApiClient().delete('/api/v1/favorites/$contentId?user_id=guest');
    } catch (_) {
      if (mounted) {
        setState(() => _items.insert(index, item));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('取消收藏失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('我的收藏 (${_items.length})',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StateView<List<dynamic>>(
        loading: _loading,
        error: _error,
        data: _items.isEmpty && !_loading ? null : _items,
        onRetry: _loadFavorites,
        loadingWidget: const LoadingSkeleton(itemCount: 4),
        builder: (items) => RefreshIndicator(
          onRefresh: _loadFavorites,
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              final type = item['content_type'] as String?;
              final color = _typeColor(type);
              return Dismissible(
                key: Key(item['content_id'] ?? '$i'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (_) => _removeFavorite(i),
                child: GestureDetector(
                  onTap: () => context.push('/content-detail', extra: {'contentId': item['content_id']}),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
                          Icon(Icons.chevron_right, size: 16, color: ShunShiColors.textTertiary),
                        ]),
                        const SizedBox(height: 6),
                        Text(item['content_id'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                      ])),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
