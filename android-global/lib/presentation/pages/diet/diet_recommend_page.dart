/// Diet recommendations: food therapy, teas and recipes picked for the user's body type and the season.
///
/// Data: `GET /api/v1/knowledge/search` (English results for the global market).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/seasons_visual.dart';
import '../../widgets/state_view.dart';

class DietRecommendPage extends StatefulWidget {
  final String? constitutionType;
  final String? season;

  /// Test hook; the app uses its configured API client.
  final Dio? client;

  const DietRecommendPage({super.key, this.constitutionType, this.season, this.client});

  @override
  State<DietRecommendPage> createState() => _DietRecommendPageState();
}

class _DietRecommendPageState extends State<DietRecommendPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _failed = false;
  String _activeFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'All', 'icon': Icons.apps},
    {'key': 'diet', 'label': 'Food therapy', 'icon': Icons.restaurant},
    {'key': 'tea', 'label': 'Herbal tea', 'icon': Icons.local_cafe},
    {'key': 'recipe', 'label': 'Recipes', 'icon': Icons.menu_book},
  ];

  static const _typeLabels = {'diet': 'Food therapy', 'tea': 'Herbal tea', 'recipe': 'Recipe'};
  static const _bodyTypeLabels = {
    'qixu': 'Qi deficiency',
    'yangxu': 'Yang deficiency',
    'yinxu': 'Yin deficiency',
    'tanshi': 'Phlegm-dampness',
    'shire': 'Damp-heat',
    'xueyu': 'Blood stasis',
    'qiyu': 'Qi stagnation',
    'tebing': 'Allergic constitution',
  };

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final params = <String, dynamic>{'q': _queryFor(widget.constitutionType), 'top_k': 20};
      if (_activeFilter != 'all') params['content_type'] = _activeFilter;
      final resp = widget.client != null
          ? await widget.client!.get('/api/v1/knowledge/search', queryParameters: params)
          : await ApiClient().get('/api/v1/knowledge/search', queryParameters: params);
      final data = resp.data;
      final raw = data is Map ? (data['results'] ?? (data['data'] is Map ? data['data']['results'] : null)) : null;
      if (raw is! List) throw const FormatException('unexpected knowledge payload');
      final list = raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((r) => _typeLabels.containsKey(r['type']))
          .toList();
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _queryFor(String? type) {
    switch (type) {
      case 'qixu':
        return 'Boost qi, support digestion';
      case 'yangxu':
        return 'Warm yang, dispel cold';
      case 'yinxu':
        return 'Nourish yin, moisten dryness';
      case 'tanshi':
        return 'Resolve phlegm and dampness';
      case 'shire':
        return 'Clear heat and dampness';
      case 'xueyu':
        return 'Move blood, clear stasis';
      case 'qiyu':
        return 'Soothe the liver, ease stagnation';
      case 'tebing':
        return 'Light, anti-allergy';
      default:
        return 'Food therapy';
    }
  }

  Future<void> _onFilterChanged(String key) async {
    if (key == _activeFilter) return;
    setState(() => _activeFilter = key);
    await _loadContent();
  }

  List<Map<String, dynamic>> get _visible =>
      _activeFilter == 'all' ? _items : _items.where((i) => i['type'] == _activeFilter).toList();

  String get _subtitle {
    final body = _bodyTypeLabels[widget.constitutionType];
    return body == null ? 'Food therapy, teas and recipes for this time of year.' : 'Picked for your body type: $body.';
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Diet recommendations',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: SgHeroBanner(
            asset: 'assets/images/sg_season_${sgSeasonFor(null)}.webp',
            title: 'Eat with the season',
            subtitle: _subtitle,
            height: 132,
          ),
        ),
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
                key: Key('diet_filter_${f['key']}'),
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
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const LoadingSkeleton(itemCount: 4)
              : _failed
                  ? ErrorView(message: "We couldn't load recommendations. Please try again.", onRetry: _loadContent)
                  : items.isEmpty
                      ? const SgEmptyState(
                          asset: 'assets/images/sg_empty.webp',
                          title: 'Nothing here yet',
                          message: 'No recommendations match this filter. Try another one.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadContent,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _card(items[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final type = item['type'] as String?;
    final title = (item['title'] ?? '').toString();
    final desc = (item['description'] ?? item['content'] ?? '').toString();
    final duration = (item['duration'] ?? '').toString().trim();
    final difficulty = (item['difficulty'] ?? '').toString().trim();
    final ingredients = (item['ingredients'] is List ? item['ingredients'] as List : const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .take(3)
        .join(', ');
    return Material(
      color: ShunShiColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('diet_card_${item['id']}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = item['id'];
          if (id != null) context.push('/content-detail', extra: {'contentId': id});
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SgThumb(asset: sgWellnessThumb(type == 'tea' ? 'tea' : 'diet', title), size: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _TypeBadge(_typeLabels[type] ?? 'Wellness'),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: ShunShiColors.textTertiary),
                ]),
                const SizedBox(height: 6),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, height: 1.25)),
                const SizedBox(height: 3),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: ShunShiColors.textSecondary, height: 1.4)),
                if (duration.isNotEmpty || difficulty.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    if (duration.isNotEmpty) ...[
                      Icon(Icons.schedule, size: 13, color: ShunShiColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(duration, style: TextStyle(fontSize: 11.5, color: ShunShiColors.textTertiary)),
                      const SizedBox(width: 10),
                    ],
                    if (difficulty.isNotEmpty) ...[
                      Icon(Icons.signal_cellular_alt, size: 13, color: ShunShiColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(difficulty, style: TextStyle(fontSize: 11.5, color: ShunShiColors.textTertiary)),
                    ],
                  ]),
                ],
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Ingredients: $ingredients',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: ShunShiColors.textTertiary)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFE4C285).withValues(alpha: 0.35), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Color(0xFF144227), fontSize: 10.5, fontWeight: FontWeight.w700)),
      );
}
