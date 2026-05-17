/// Wellness Library — wired to /intl/contents/recommend API
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class WellnessLibraryPage extends StatefulWidget {
  const WellnessLibraryPage({super.key});

  @override
  State<WellnessLibraryPage> createState() => _WellnessLibraryPageState();
}

class _WellnessLibraryPageState extends State<WellnessLibraryPage> {
  static const _baseUrl = 'http://116.62.32.43:4000';
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  List<Map<String, dynamic>> _contents = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeFilter = 'All';
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();

  static const _filters = ['All', 'Sleep', 'Nutrition', 'Movement', 'Mindfulness', 'Seasonal'];

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
    if (filter == 'All') {
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
      case 'movement': return const Color(0xFF533afd);
      case 'mindfulness': return const Color(0xFF00BCD4);
      case 'seasonal': return const Color(0xFFFF9800);
      default: return const Color(0xFF533afd);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF533afd)))
          : RefreshIndicator(
              color: const Color(0xFF533afd),
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
                          const Icon(Icons.menu, color: Color(0xFF533afd)),
                          const Spacer(),
                          Text('SEASONS', style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF533afd),
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
                      child: Text('Wellness Library', style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
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
                          color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => _search(v),
                          decoration: InputDecoration(
                            hintText: 'Search wellness content...',
                            hintStyle: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: ShunShiColors.textTertiary, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: ShunShiColors.textTertiary),
                              onPressed: () { _searchController.clear(); _search(''); },
                            ) : null,
                          ),
                          style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary),
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
                          ? Center(child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text('No content found for this filter', style: TextStyle(color: ShunShiColors.textTertiary)),
                            ))
                          : Column(
                              children: _filtered.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildContentCard(
                                  icon: _iconForType(item['type']),
                                  category: (item['category'] ?? 'general').toString().capitalize(),
                                  title: item['title'] ?? 'Untitled',
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
            color: active ? const Color(0xFF533afd) : ShunShiColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? const Color(0xFF533afd) : ShunShiColors.borderGhost),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: active ? Colors.white : ShunShiColors.textSecondary,
          )),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required IconData icon, required String category,
    required String title, required String desc, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.4)),
        ])),
        Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
      ]),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
