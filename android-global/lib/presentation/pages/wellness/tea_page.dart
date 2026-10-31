import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../../data/en_content.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/seasons_visual.dart';
import '../../../core/theme/app_localizations.dart';

/// Seasonal tea recommendations page
class TeaPage extends StatefulWidget {
  const TeaPage({super.key});

  @override
  State<TeaPage> createState() => _TeaPageState();
}

class _TeaPageState extends State<TeaPage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  String _selectedTimeOfDay = 'all';
  String? _selectedSeason;

  static const List<Map<String, String>> _seasonFilters = [
    {'value': 'spring', 'label': 'Spring'},
    {'value': 'summer', 'label': 'Summer'},
    {'value': 'autumn', 'label': 'Autumn'},
    {'value': 'winter', 'label': 'Winter'},
    {'value': 'all', 'label': 'All seasons'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Use local English content first
    final localItems = EnContentData.teas.map((c) => EnContentData.toMap(c)).toList();
    setState(() {
      _items = localItems;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _parseItems(dynamic data) {
    if (data is Map && data['items'] != null) {
      return List<Map<String, dynamic>>.from(data['items']);
    }
    if (data is Map && data['data'] != null && data['data']['items'] != null) {
      return List<Map<String, dynamic>>.from(data['data']['items']);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> get _filteredTeas {
    return _items.where((tea) {
      if (_selectedTimeOfDay != 'all' && _bestTime(tea) != _selectedTimeOfDay) return false;
      if (_selectedSeason != null && tea['season'] != _selectedSeason && tea['season'] != 'all') return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: const Text('Seasonal teas'),
        backgroundColor: isDark ? ShunShiColors.darkSurface : const Color(0xFFFDF9F0),
      ),
      body: _buildBody(),
    );
  }


  Widget _header() {
    return Column(children: [
      const SgHeroBanner(
        asset: 'assets/images/sgx_hero_tea.webp',
        title: 'Seasonal tea table',
        subtitle: 'Pick a time of day and a season.',
        height: 150,
      ),
      const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF4F1E6), borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('wellness_best_time_to_drink'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTimeChip('all', 'All Day', Icons.wb_sunny),
                    _buildTimeChip('morning', 'Morning', Icons.wb_twilight),
                    _buildTimeChip('afternoon', 'Afternoon', Icons.wb_cloudy),
                    _buildTimeChip('evening', 'Evening', Icons.nightlight),
                  ],
                ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).t('wellness_select_season'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _seasonFilters.map((s) {
                    final v = s['value']!;
                    final l = s['label']!;
                    return FilterChip(
                      label: Text(l),
                      selected: _selectedSeason == v,
                      onSelected: (selected) {
                        setState(() => _selectedSeason = selected ? v : null);
                      },
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SkeletonList(itemCount: 5, itemHeight: 120);
    }
    if (_filteredTeas.isEmpty && _error == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        _header(),
        SgEmptyState(
          asset: 'assets/images/sg_empty.webp',
          title: 'No teas match these filters',
          message: AppLocalizations.of(context).t('exercise_no_content'),
        ),
      ]);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: Text(AppLocalizations.of(context).t('retry'))),
          ],
        ),
      );
    }
    final filtered = _filteredTeas;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _header();
          return _TeaCard(tea: filtered[index - 1]);
        },
      ),
    );
  }

  Widget _buildTimeChip(String value, String label, IconData icon) {
    final isSelected = _selectedTimeOfDay == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.green),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeOfDay = value);
      },
      selectedColor: Colors.green,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }
}

/// The time of day a tea suits: the item's own best_time, else a time-of-day word in its tags.
String _bestTime(Map<String, dynamic> tea) {
  final own = tea['best_time'];
  if (own is String && own.isNotEmpty) return own;
  final tags = tea['tags'];
  if (tags is List) {
    for (final t in tags) {
      if (t == 'morning' || t == 'afternoon' || t == 'evening') return '$t';
    }
  }
  return 'all';
}

class _TeaCard extends StatelessWidget {
  final Map<String, dynamic> tea;

  const _TeaCard({required this.tea});

  static const Map<String, String> _photos = {
    'tea_green': 'assets/images/sgx_drink_green.webp',
    'tea_jasmine': 'assets/images/sgx_drink_jasmine.webp',
    'tea_oolong': 'assets/images/sgx_drink_oolong.webp',
    'tea_puerh': 'assets/images/sgx_drink_puerh.webp',
    'tea_pu_erh': 'assets/images/sgx_drink_puerh.webp',
    'tea_chamomile': 'assets/images/sgx_drink_chamomile.webp',
    'tea_chrysanthemum': 'assets/images/sgx_drink_chrysanthemum.webp',
  };

  String get _photo => _photos[tea['id']] ?? sgWellnessThumb('tea', '${tea['title']}');

  @override
  Widget build(BuildContext context) {
    final ingredients = tea['ingredients'] is List ? (tea['ingredients'] as List).map((e) => '$e').toList() : <String>[];
    final benefits = tea['benefits'] is List ? (tea['benefits'] as List).map((e) => '$e').toList() : <String>[];
    final steps = tea['steps'] is List ? (tea['steps'] as List).map((e) => '$e').toList() : <String>[];
    final duration = (tea['duration'] ?? '').toString();
    final season = (tea['season'] ?? '').toString();
    final timeLabel = _getTimeLabel(_bestTime(tea));
    final desc = (tea['description'] ?? '').toString();

    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF1EEE4), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: const Color(0xFF5E6B62)),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF5E6B62))),
          ]),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E1D2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(children: [
            SgThumb(asset: _photo, size: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tea['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF144227))),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  chip(Icons.schedule, duration.isNotEmpty ? duration : timeLabel),
                  if (season.isNotEmpty && season != 'all') chip(Icons.eco_outlined, '${season[0].toUpperCase()}${season.substring(1)}'),
                  if ((tea['category'] ?? '').toString().isNotEmpty) chip(Icons.local_cafe_outlined, '${tea['category']}'),
                ]),
              ]),
            ),
          ]),
          children: [
            if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF3C4A41))),
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final b in benefits) chip(Icons.check_circle_outline, b)]),
            ],
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('You will need', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final i in ingredients)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('•  $i', style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF5E6B62))),
                ),
            ],
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('How to brew', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (var n = 0; n < steps.length; n++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFF144227), shape: BoxShape.circle),
                      child: Text('${n + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[n], style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF3C4A41)))),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeLabel(String timeOfDay) {
    const labels = {
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'all': 'All Day',
    };
    return labels[timeOfDay] ?? timeOfDay;
  }
}
