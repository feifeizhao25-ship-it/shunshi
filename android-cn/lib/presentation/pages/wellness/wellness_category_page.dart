import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../data/network/api_client.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/wellness_assets.dart';

/// 养生分类详情页 — 饮食/茶饮/运动/穴位/睡眠/情绪
class WellnessCategoryPage extends StatefulWidget {
  final String type; // food_therapy / tea / exercise / acupoint / sleep_tip / emotion

  const WellnessCategoryPage({super.key, required this.type});

  @override
  State<WellnessCategoryPage> createState() => _WellnessCategoryPageState();
}

class _WellnessCategoryPageState extends State<WellnessCategoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';

  static const _categoryMeta = {
    'food_therapy': {'title': '食疗养生', 'emoji': '🥣', 'color': Color(0xFFE8A87C), 'desc': '药食同源，以食养身'},
    'tea': {'title': '茶饮养生', 'emoji': '🍵', 'color': Color(0xFFA8D8B9), 'desc': '一杯好茶，养生有道'},
    'exercise': {'title': '运动导引', 'emoji': '🧘', 'color': Color(0xFF87CEEB), 'desc': '动静结合，强身健体'},
    'acupoint': {'title': '穴位保健', 'emoji': '✋', 'color': Color(0xFFDDA0DD), 'desc': '经络通畅，气血调和'},
    'acupressure': {'title': '穴位按摩', 'emoji': '🤲', 'color': Color(0xFFDDA0DD), 'desc': '按揉穴位，调理身心'},
    'sleep_tip': {'title': '睡眠调理', 'emoji': '😴', 'color': Color(0xFFB0C4DE), 'desc': '好眠是最好的补药'},
    'emotion': {'title': '情志调摄', 'emoji': '🌿', 'color': Color(0xFF98D8C8), 'desc': '调畅情志，身心和谐'},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.baseUrl,
        headers: {'ngrok-skip-browser-warning': 'true'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final resp = await dio.get('/api/v1/contents', queryParameters: {
        'type': widget.type,
        'limit': 50,
      });
      if (resp.statusCode == 200 && mounted) {
        final data = resp.data;
        final items = (data is Map && data['data'] != null)
            ? (data['data']['items'] as List? ?? [])
            : (data is List ? data : <dynamic>[]);
        setState(() {
          _items = items.map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '加载失败，请检查网络'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[widget.type] ?? {'title': '养生知识', 'emoji': '📋', 'color': ShunShiColors.primary, 'desc': ''};

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: ShunShiColors.background,
        appBar: AppBar(
          backgroundColor: ShunShiColors.background,
          foregroundColor: ShunShiColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          title: Row(
          children: [
            Text(meta['emoji'] as String, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(meta['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: ShunShiTypography.bodyMedium.copyWith(color: ShunShiColors.textSecondary)))
              : RefreshIndicator(
                  color: ShunShiColors.primary,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ContentCard(
                        item: item,
                        type: widget.type,
                        accentColor: meta['color'] as Color,
                        onTap: () => _showDetail(context, item),
                      );
                    },
                  ),
                ),
        ),
      );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShunShiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => _DetailSheet(item: item, type: widget.type, scrollController: scrollCtrl),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  final Color accentColor;
  final VoidCallback onTap;

  const _ContentCard({required this.item, required this.type, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '未命名';
    final summary = item['summary'] ?? item['content'] ?? '';
    final tags = item['tags'] as List? ?? [];
    final itemId = item['id']?.toString() ?? '';
    const categoryEmojis = {
      'food_therapy': '🥣', 'tea': '🍵', 'exercise': '🧘',
      'acupoint': '✋', 'acupressure': '🤲', 'sleep_tip': '😴', 'emotion': '🌬️',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: ShunShiTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  WellnessAssets.getImageForType(type, itemId),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.1)],
                      ),
                    ),
                    child: Center(child: Text(categoryEmojis[type] ?? '📋', style: const TextStyle(fontSize: 48))),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            // 摘要
            if (summary.toString().isNotEmpty)
              Text(
                summary.toString().length > 100 ? '${summary.toString().substring(0, 100)}...' : summary.toString(),
                style: ShunShiTypography.bodySmall.copyWith(color: ShunShiColors.textSecondary, height: 1.6),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            // 标签
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.take(4).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(t.toString(), style: ShunShiTypography.caption.copyWith(color: accentColor, fontSize: 10)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  final ScrollController scrollController;

  const _DetailSheet({required this.item, required this.type, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '';
    final content = item['content'] as String? ?? item['summary'] as String? ?? '';
    final tags = item['tags'] as List? ?? [];
    final season = item['season_tag'] as String? ?? '';
    final imageUrl = item['image_url'] as String? ?? '';

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        // 拖动指示条
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: ShunShiColors.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        // 标题
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 8),
        // 标签
        if (tags.isNotEmpty || season.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (season.isNotEmpty) _tag(season, ShunShiColors.primary),
              ...tags.take(5).map((t) => _tag(t.toString(), ShunShiColors.textSecondary)),
            ],
          ),
        const SizedBox(height: 16),
        // 图片 — 穴位优先用穴位图
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Builder(builder: (ctx) {
            final title = item['title']?.toString() ?? '';
            final isAcupoint = type == 'acupoint' || type == 'acupressure';
            final acupointImg = isAcupoint ? WellnessAssets.getAcupointImage(title) : null;
            final imgPath = acupointImg ?? WellnessAssets.getImageForType(type, item['id']?.toString());
            return Image.asset(imgPath, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ShunShiColors.primary.withValues(alpha: 0.3), ShunShiColors.primary.withValues(alpha: 0.05)],
                  ),
                ),
                child: const Center(child: Text('📋', style: TextStyle(fontSize: 48))),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // 内容 — 按 \n 分段，**bold** 处理
        ..._parseContent(content),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: ShunShiTypography.caption.copyWith(color: color)),
    );
  }

  List<Widget> _parseContent(String text) {
    if (text.isEmpty) return [Text('暂无详细内容', style: ShunShiTypography.bodyMedium.copyWith(color: ShunShiColors.textSecondary))];
    final paragraphs = text.split('\n').where((p) => p.trim().isNotEmpty).toList();
    return paragraphs.map((p) {
      // 处理 **粗体**
      final spans = <InlineSpan>[];
      final boldRegex = RegExp(r'\*\*(.+?)\*\*');
      final parts = p.split(boldRegex);
      final matches = boldRegex.allMatches(p).toList();

      for (var i = 0; i < parts.length; i++) {
        if (i < matches.length && i > 0) {
          spans.add(TextSpan(text: matches[i - 1].group(1), style: const TextStyle(fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)));
        }
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(text: parts[i], style: ShunShiTypography.bodyMedium.copyWith(color: ShunShiColors.textSecondary, height: 1.8)));
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RichText(text: TextSpan(children: spans.isEmpty ? [TextSpan(text: p, style: ShunShiTypography.bodyMedium.copyWith(color: ShunShiColors.textSecondary, height: 1.8))] : spans)),
      );
    }).toList();
  }
}
