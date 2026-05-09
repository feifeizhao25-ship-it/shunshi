import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/skeleton_loading.dart';
import '../../../core/theme/app_localizations.dart';

/// Sleep改善页面
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  String _sleepQuality = 'normal';
  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': 'Sleep Techniques', 'label': 'Sleep Techniques'},
    {'value': 'Pre-Sleep Habits', 'label': 'Pre-Sleep Habits'},
    {'value': 'ShiChen Wellness', 'label': 'ShiChen Wellness'},
    {'value': 'Environment Adjustment', 'label': 'Environment Adjustment'},
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
        'type': 'sleep',
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

  List<Map<String, dynamic>> get _filteredTips {
    if (_selectedCategory == null) return _items;
    return _items.where((t) => t['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).t('wellness_sleep_improvement')),
        backgroundColor: Colors.indigo[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('wellness_how_was_your_sleep_last_night'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQualityButton('poor', '😫 Bad'),
                    _buildQualityButton('normal', '😐 Okay'),
                    _buildQualityButton('good', '😊 Good'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).t('wellness_suggested_categories'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(AppLocalizations.of(context).t('exercise_all')),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                      selectedColor:
                          Colors.indigo.withValues(alpha: 0.2),
                    ),
                    ..._categories.map((c) {
                      final isSelected =
                          _selectedCategory == c['value'];
                      return FilterChip(
                        label: Text(c['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory =
                              selected ? c['value'] : null);
                        },
                        selectedColor:
                            Colors.indigo.withValues(alpha: 0.2),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
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
    final filtered = _filteredTips;
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
          final tip = filtered[index];
          return _buildTipCard(tip);
        },
      ),
    );
  }

  Widget _buildQualityButton(String quality, String label) {
    final isSelected = _sleepQuality == quality;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _sleepQuality = quality);
        }
      },
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final icon = _getIconForCategory(tip['category'] ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[100],
          child: Icon(icon, color: Colors.indigo[700]),
        ),
        title: Text(tip['title'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tip['description'] ?? '',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: tip['category'] != null
            ? Chip(
                label: Text(tip['category'],
                    style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.indigo[50],
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
        onTap: () => _showTipDetail(tip),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Sleep Techniques':
        return Icons.self_improvement;
      case 'Pre-Sleep Habits':
        return Icons.bedtime;
      case 'ShiChen Wellness':
        return Icons.dark_mode;
      case 'Environment Adjustment':
        return Icons.light_mode;
      default:
        return Icons.nightlight;
    }
  }

  void _showTipDetail(Map<String, dynamic> tip) {
    final steps = tip['steps'] is List ? tip['steps'] as List : <dynamic>[];
    final icon = _getIconForCategory(tip['category'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Icon(icon, color: Colors.indigo[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tip['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tip['description'] != null)
                Text(tip['description'],
                    style: const TextStyle(fontSize: 15, height: 1.6)),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context).t('wellness_specific_steps'),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(steps.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.indigo[100],
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.indigo[800])),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(steps[i].toString(),
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4))),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).t('wellness_got_it')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
