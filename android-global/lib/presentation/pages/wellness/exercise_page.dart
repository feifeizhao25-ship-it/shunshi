import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../data/network/api_client.dart';
import '../../../data/en_content.dart';
import '../../../design_system/theme.dart';
import '../../widgets/exercise_demo.dart';
import '../../widgets/skeleton_loading.dart';

/// ExerciseQigong页面
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': 'Traditional Qigong', 'label': 'Traditional Qigong', 'emoji': '🧘‍♂️'},
    {'value': 'Daily Exercise', 'label': 'Daily Exercise', 'emoji': '🏃‍♂️'},
    {'value': 'Office Exercise', 'label': 'Office Exercise', 'emoji': '💼'},
    {'value': 'Seasonal Exercise', 'label': 'Seasonal Exercise', 'emoji': '🌱'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Use local English content first
    final localItems = EnContentData.exercises.map((c) => EnContentData.toMap(c)).toList();
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

  List<Map<String, dynamic>> get _filteredExercises {
    if (_selectedCategory == null) return _items;
    return _items.where((e) => e['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop()),
        title: Text(AppLocalizations.of(context).get('exercise_qigong')),
        backgroundColor: isDark ? ShunShiColors.darkSurface : Colors.orange[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).get('exercise_type'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(AppLocalizations.of(context).get('exercise_all')),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                      selectedColor:
                          Colors.orange.withValues(alpha: 0.2),
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
                            Colors.orange.withValues(alpha: 0.2),
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
            ElevatedButton(onPressed: _loadData, child: Text(AppLocalizations.of(context).get('retry'))),
          ],
        ),
      );
    }
    final filtered = _filteredExercises;
    if (filtered.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context).get('exercise_no_content'), style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExerciseDemo(),
          const SizedBox(height: 20),
          Text(
            'MoreQigong',
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.map((exercise) => _ExerciseCard(
                exercise: exercise,
                onTap: () => _showExerciseDetail(exercise),
              )),
        ],
      ),
    );
  }

  void _showExerciseDetail(Map<String, dynamic> exercise) {
    final steps = exercise['steps'] is List ? exercise['steps'] as List : <dynamic>[];
    final tags = exercise['tags'] is List ? exercise['tags'] as List : <dynamic>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(exercise['emoji'] ?? '🧘‍♂️',
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTag(exercise['duration'] ?? '', ShunShiColors.borderGhost!),
                  _buildTag(exercise['difficulty'] ?? '', Colors.green[100]!),
                  _buildTag(exercise['category'] ?? '', Colors.orange[100]!),
                  ...tags.map((t) => _buildTag(t.toString(), Colors.blue[50]!)),
                ],
              ),
              const SizedBox(height: 16),
              if (exercise['description'] != null)
                Text(exercise['description'],
                    style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              if (exercise['benefits'] != null)
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise['benefits'] is List
                                ? (exercise['benefits'] as List).join(', ')
                                : exercise['benefits'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context).get('exercise_movement'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(
                  steps.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.orange[100],
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange[800])),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(steps[i].toString(),
                              style: const TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chat');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppLocalizations.of(context).get('exercise_start_ai')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final benefits = exercise['benefits'] is List
        ? (exercise['benefits'] as List).join(', ')
        : (exercise['benefits'] ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(exercise['emoji'] ?? '🧘‍♂️',
                        style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise['category'] ?? ''} · ${exercise['duration'] ?? ''} · ${exercise['difficulty'] ?? ''}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (benefits.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        benefits,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange[700]),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
