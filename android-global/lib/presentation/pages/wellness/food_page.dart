import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/food_card.dart';
import '../../widgets/skeleton_loading.dart';
import '../../../core/theme/app_localizations.dart';

/// Food Therapyrecommended 页面
class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedSeason;
  String? _selectedConstitution;

  static const List<Map<String, String>> _seasonFilters = [
    {'value': 'spring', 'label': 'Spring'},
    {'value': 'summer', 'label': 'Summer'},
    {'value': 'autumn', 'label': 'Autumn'},
    {'value': 'winter', 'label': 'Winter'},
    {'value': 'all', 'label': 'All Seasons'},
  ];

  static const List<String> _constitutionFilters = [
    'Heavy Dampness', 'Liver Fire', 'Cold Body', 'Qi-Blood Deficient', 'Heart Fire', 'Yin Deficient', 'Phlegm-Damp', 'Damp-Heat', 'Qi Deficient', 'Yang Deficient',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/api/v1/contents', queryParameters: {
        'type': 'recipe',
        'limit': '20',
      });
      final data = res.data;
      final items = _parseItems(data);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Load failed';
        _isLoading = false;
      });
    }
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

  List<Map<String, dynamic>> get _filteredFoods {
    return _items.where((food) {
      if (_selectedSeason != null && food['season_tag'] != _selectedSeason) return false;
      if (_selectedConstitution != null) {
        final tags = food['tags'];
        if (tags == null || !(tags is List && tags.contains(_selectedConstitution))) return false;
      }
      return true;
    }).toList();
  }

  static String _seasonLabel(String? season) {
    switch (season) {
      case 'spring':
        return 'Spring';
      case 'summer':
        return 'Summer';
      case 'autumn':
        return 'Autumn';
      case 'winter':
        return 'Winter';
      default:
        return 'Four Seasons';
    }
  }

  static IconData _seasonIcon(String? season) {
    switch (season) {
      case 'spring':
        return Icons.eco;
      case 'summer':
        return Icons.wb_sunny;
      case 'autumn':
        return Icons.air;
      case 'winter':
        return Icons.ac_unit;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).t('wellness_food_therapyrecommended')),
        backgroundColor: Colors.red[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('wellness_select_season'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _seasonFilters.map((f) {
                    final v = f['value']!;
                    final l = f['label']!;
                    final colors = {
                      'spring': Colors.green,
                      'summer': Colors.red,
                      'autumn': Colors.orange,
                      'winter': Colors.blue,
                      'all': Colors.grey,
                    };
                    return _buildFilterChip(v, l, colors[v]!);
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).t('wellness_body_type'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _constitutionFilters
                      .map((c) => _buildConstitutionChip(c))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SkeletonList(itemCount: 5, itemHeight: 80);
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
    final filtered = _filteredFoods;
    if (filtered.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context).t('exercise_no_content'), style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final food = filtered[index];
          final season = food['season_tag'] as String? ?? 'all';
          return FoodCard(
            food: FoodCardData(
              name: food['title'] ?? '',
              seasonTag: _seasonLabel(season),
              seasonEmoji: food['emoji'] ?? '🍲',
              description: food['description'] ?? food['benefits']?.join('、') ?? '',
              difficulty: food['difficulty'] ?? '',
              category: food['category'] ?? '',
              ingredients: food['ingredients'] is List
                  ? (food['ingredients'] as List).join('、')
                  : (food['ingredients'] ?? ''),
              effect: food['benefits'] is List
                  ? (food['benefits'] as List).join('、')
                  : (food['benefits'] ?? ''),
              recipe: food['steps'] is List
                  ? (food['steps'] as List).asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')
                  : (food['steps'] ?? ''),
              icon: _seasonIcon(season),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedSeason == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSeason = selected ? value : null);
      },
      selectedColor: color.withValues(alpha: 0.3),
    );
  }

  Widget _buildConstitutionChip(String value) {
    final isSelected = _selectedConstitution == value;
    return FilterChip(
      label: Text(value, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedConstitution = selected ? value : null);
      },
    );
  }
}
