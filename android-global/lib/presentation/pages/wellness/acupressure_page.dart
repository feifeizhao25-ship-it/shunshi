import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/network/api_client.dart';
import '../../../data/en_content.dart';
import '../../widgets/acupoint_diagram.dart';
import '../../widgets/skeleton_loading.dart';
import '../../../core/theme/app_localizations.dart';

/// Acupressure保健页面
class AcupressurePage extends StatefulWidget {
  const AcupressurePage({super.key});

  @override
  State<AcupressurePage> createState() => _AcupressurePageState();
}

class _AcupressurePageState extends State<AcupressurePage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': 'Head', 'label': 'Head', 'emoji': '🧠'},
    {'value': 'Upper Body', 'label': 'Upper Body', 'emoji': '✋'},
    {'value': 'Lower Body', 'label': 'Lower Body', 'emoji': '🦵'},
    {'value': 'Back', 'label': 'Back', 'emoji': '🔙'},
    {'value': 'Chest & Abdomen', 'label': 'Chest & Abdomen', 'emoji': '🫁'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Use local English content first
    final localItems = EnContentData.acupoints.map((c) => EnContentData.toMap(c)).toList();
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

  List<Map<String, dynamic>> get _filteredAcupoints {
    if (_selectedCategory == null) return _items;
    return _items.where((p) => p['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).t('wellness_acupressure_wellness')),
        backgroundColor: Colors.purple[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('wellness_select_area'), style: TextStyle(fontWeight: FontWeight.bold)),
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
                          Colors.purple.withValues(alpha: 0.2),
                    ),
                    ..._categories.map((c) {
                      final isSelected =
                          _selectedCategory == c['value'];
                      return FilterChip(
                        label: Text('${c['emoji']} ${c['label']}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory =
                              selected ? c['value'] : null);
                        },
                        selectedColor:
                            Colors.purple.withValues(alpha: 0.2),
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
    final filtered = _filteredAcupoints;
    if (filtered.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context).t('exercise_no_content'), style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AcupointDiagram(),
          const SizedBox(height: 20),
          ...filtered.map((point) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Text(point['emoji'] ?? '📍',
                        style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(point['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${point['category'] ?? ''} · ${point['description'] ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (point['description'] != null)
                            _buildInfoRow('Benefits', point['description']),
                          if (point['duration'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Duration', point['duration']),
                          ],
                          if (point['difficulty'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Difficulty', point['difficulty']),
                          ],
                          if (point['steps'] != null && point['steps'] is List) ...[
                            const SizedBox(height: 12),
                            Text(AppLocalizations.of(context).t('wellness_massage_steps'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...(point['steps'] as List)
                                .map((s) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 4),
                                      child: Text('• $s',
                                          style: const TextStyle(
                                              height: 1.5)),
                                    )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text('$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
            child: Text(value.toString(),
                style: const TextStyle(height: 1.4))),
      ],
    );
  }
}
