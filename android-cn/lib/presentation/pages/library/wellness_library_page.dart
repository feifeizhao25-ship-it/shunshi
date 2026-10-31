/// Wellness Library — wired to /intl/contents/recommend API
library;

import '../../widgets/illustrated_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';

class WellnessLibraryPage extends StatefulWidget {
  const WellnessLibraryPage({super.key});

  @override
  State<WellnessLibraryPage> createState() => _WellnessLibraryPageState();
}

class _WellnessLibraryPageState extends State<WellnessLibraryPage> {
  static final String _baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  List<Map<String, dynamic>> _contents = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeFilter = '全部';
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();

  static const _filters = ['全部', '睡眠', '饮食', '运动', '冥想', '节气养生'];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searching = false; _filtered = _contents; });
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await _dio.get('/api/v1/contents/search', queryParameters: {'q': query.trim()});
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final items = data['data']['items'];
        if (items is List) _filtered = items.cast<Map<String, dynamic>>();
      }
      setState(() {});
    } catch (_) { if (mounted) setState(() {}); }
  }

  @override
  void initState() {
    super.initState();
    _fetchContents();
  }

  Future<void> _fetchContents() async {
    try {
      final res = await _dio.get('/api/v1/contents/recommend', queryParameters: {'limit': 20});
      if (!mounted) return;
      final data = res.data;
      if (data is Map && data['data'] is List) {
        _contents = (data['data'] as List).cast<Map<String, dynamic>>();
        _applyFilter(_activeFilter);
      }
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter(String filter) {
    _activeFilter = filter;
    if (filter == '全部') {
      _filtered = List.from(_contents);
    } else {
      final lower = filter.toLowerCase();
      _filtered = _contents.where((c) {
        final cat = (c['category'] ?? '').toString().toLowerCase();
        final tags = (c['tags'] as List?)?.map((t) => t.toString().toLowerCase()) ?? <String>[];
        return cat == lower || tags.contains(lower);
      }).toList();
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'recipe': return Icons.restaurant;
      case 'exercise': return Icons.self_improvement;
      case 'meditation': return Icons.spa;
      case 'article': return Icons.article;
      default: return Icons.eco;
    }
  }

  Color _colorForCategory(String? category) {
    switch (category) {
      case 'sleep': return const Color(0xFF3F51B5);
      case 'nutrition': return const Color(0xFF4CAF50);
      case 'movement': return AppColors.primary(context);
      case 'mindfulness': return const Color(0xFF00BCD4);
      case 'seasonal': return const Color(0xFFFF9800);
      default: return AppColors.primary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background(context);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
          : RefreshIndicator(
              color: AppColors.primary(context),
              onRefresh: _fetchContents,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary(context), size: 18),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          Text('顺时', style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary(context),
                          )),
                          const Spacer(),
                          const SizedBox(width: 24),
                        ]),
                      ),
                    ),
                  ),

                  // Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Text('养生文库', style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
                      )),
                    ),
                  ),

                  // Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow(context), borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => _search(v),
                          decoration: InputDecoration(
                            hintText: '搜索养生内容',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary(context)),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: AppColors.textTertiary(context), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: AppColors.textTertiary(context)),
                              onPressed: () { _searchController.clear(); _search(''); },
                            ) : null,
                          ),
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
                        ),
                      ),
                    ),
                  ),

                  // Filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _filters.map((f) => _buildChip(f, f == _activeFilter)).toList()),
                      ),
                    ),
                  ),

                  // Content items
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: _filtered.isEmpty
                          ? const Center(child: IllustratedEmptyState(
                              title: '这个分类下还没有内容',
                              message: '换一个分类看看，或稍后再来。我们会陆续整理并审核新的养生内容。',
                            ))
                          : Column(
                              children: _filtered.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildContentCard(
                                  icon: _iconForType(item['type']),
                                  category: (item['category'] ?? '').toString(),
                                  title: item['title'] ?? '未命名',
                                  desc: item['subtitle'] ?? item['description']?.toString().substring(0, (item['description']?.toString().length ?? 50).clamp(0, 80)) ?? '',
                                  color: _colorForCategory(item['category']),
                                ),
                              )).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChip(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _applyFilter(label)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary(context) : AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.primary(context) : AppColors.borderGhost(context)),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: active ? AppColors.onPrimary(context) : AppColors.textSecondary(context),
          )),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required IconData icon, required String category,
    required String title, required String desc, required Color color,
  }) {
    return LibraryCard(
      asset: libraryCategoryCover(category),
      categoryLabel: libraryCategoryLabel(category),
      icon: icon,
      title: title,
      desc: desc,
    );
  }
}
