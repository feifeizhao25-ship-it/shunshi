import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/skeleton_loading.dart';

/// 茶饮推荐页面
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
    {'value': 'spring', 'label': '🌸 春'},
    {'value': 'summer', 'label': '☀️ 夏'},
    {'value': 'autumn', 'label': '🍂 秋'},
    {'value': 'winter', 'label': '❄️ 冬'},
    {'value': 'all', 'label': '🌿 四季'},
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
        'type': 'tea',
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
        _error = '加载失败';
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

  List<Map<String, dynamic>> get _filteredTeas {
    return _items.where((tea) {
      if (_selectedTimeOfDay != 'all' && tea['best_time'] != _selectedTimeOfDay) return false;
      if (_selectedSeason != null && tea['season_tag'] != _selectedSeason) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: const Text('茶饮推荐'),
        backgroundColor: Colors.green[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('饮用时间', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTimeChip('all', '全天', Icons.wb_sunny),
                    _buildTimeChip('morning', '早上', Icons.wb_twilight),
                    _buildTimeChip('afternoon', '下午', Icons.wb_cloudy),
                    _buildTimeChip('evening', '晚上', Icons.nightlight),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('选择季节', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SkeletonList(itemCount: 5, itemHeight: 120);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }
    final filtered = _filteredTeas;
    if (filtered.isEmpty) {
      return const Center(
          child: Text('暂无内容', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final tea = filtered[index];
          return _TeaCard(tea: tea);
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

class _TeaCard extends StatelessWidget {
  final Map<String, dynamic> tea;

  const _TeaCard({required this.tea});

  Color get _teaColor {
    final tags = tea['tags'];
    final tagStr = tags is List ? tags.join(',') : (tags ?? '');
    if (tagStr.contains('清热') || tagStr.contains('green')) return Colors.green;
    if (tagStr.contains('补血') || tagStr.contains('red')) return Colors.red[300]!;
    if (tagStr.contains('养阴') || tagStr.contains('white')) return Colors.grey[400]!;
    if (tagStr.contains('疏肝') || tagStr.contains('pink')) return Colors.pink;
    if (tagStr.contains('orange')) return Colors.orange;
    final cat = tea['category'] ?? '';
    if (cat.contains('花茶')) return Colors.pink;
    if (cat.contains('绿茶')) return Colors.green;
    if (cat.contains('红茶')) return Colors.red[300]!;
    return Colors.brown;
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = tea['ingredients'] is List
        ? (tea['ingredients'] as List).join('、')
        : (tea['ingredients'] ?? '');
    final benefits = tea['benefits'] is List
        ? (tea['benefits'] as List).join('、')
        : (tea['benefits'] ?? '');
    final steps = tea['steps'] is List
        ? (tea['steps'] as List).join('\n')
        : (tea['steps'] ?? '');
    final tags = tea['tags'] is List ? (tea['tags'] as List).join('、') : '';
    final timeLabel = _getTimeLabel(tea['best_time'] ?? 'all');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _teaColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(tea['emoji'] ?? '🍵',
                          style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tea['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(timeLabel,
                              style: TextStyle(color: Colors.grey[600])),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(tags,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(benefits,
                style: TextStyle(
                    color: Colors.green[700], fontWeight: FontWeight.w500)),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('材料：$ingredients',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('冲泡：$steps',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (tea['description'] != null && tea['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tea['description'],
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeLabel(String timeOfDay) {
    const labels = {
      'morning': '早上',
      'afternoon': '下午',
      'evening': '晚上',
      'all': '全天',
    };
    return labels[timeOfDay] ?? timeOfDay;
  }
}
