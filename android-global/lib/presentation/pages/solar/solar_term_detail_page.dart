import 'package:flutter/material.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';

/// Solar Term Detail Page - Enhanced
class SolarTermDetailPage extends StatefulWidget {
  final String termName;
  final String? termNameEn;
  final String? emoji;
  final String? season;

  const SolarTermDetailPage({super.key, required this.termName, this.termNameEn, this.emoji, this.season});

  @override
  State<SolarTermDetailPage> createState() => _SolarTermDetailPageState();
}

class _SolarTermDetailPageState extends State<SolarTermDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _termDetail;
  Map<String, dynamic>? _currentTerm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.emoji ?? ''} ${widget.termNameEn ?? widget.termName}'), elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_currentTerm != null) _buildCurrentBanner(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: SeasonsColors.primaryDark,
                    unselectedLabelColor: SeasonsColors.textSecondary,
                    indicatorColor: SeasonsColors.primaryDark,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: SeasonsTextStyles.caption,
                    tabs: const [
                      Tab(text: 'Diet'), Tab(text: 'Tea'), Tab(text: 'Exercise'),
                      Tab(text: 'Acupoints'), Tab(text: 'Sleep'), Tab(text: 'Routine'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentTab('diet', 'No diet recommendations yet'),
                      _buildContentTab('tea', 'No tea recommendations yet'),
                      _buildContentTab('exercise', 'No exercise recommendations yet'),
                      _buildContentTab('acupoints', 'No acupressure recommendations yet'),
                      _buildContentTab('sleep', 'No sleep tips yet'),
                      _buildRoutineTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentBanner() {
    final current = _currentTerm!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getSeasonGradient(widget.season ?? 'spring'), begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current: ${current['name_en'] ?? widget.termNameEn ?? widget.termName}', style: SeasonsTextStyles.heading.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          if (current['days_remaining'] != null)
            Text('${current['days_remaining']} days until next term', style: SeasonsTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildContentTab(String key, String emptyText) {
    final items = (_termDetail?['wellness_plan']?[key] as List?) ?? [];
    if (items.isEmpty) return Center(child: Text(emptyText, style: SeasonsTextStyles.body));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: SeasonsColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: SeasonsColors.border, width: 0.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['title'] ?? '', style: SeasonsTextStyles.body.copyWith(fontWeight: FontWeight.w400)),
              if (item['description'] != null) ...[
                const SizedBox(height: 4),
                Text(item['description'].toString(), style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineTab() {
    final routine = (_termDetail?['wellness_plan']?['routine'] as Map?) ?? {};
    if (routine.isEmpty) return const Center(child: Text('No routine advice available'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRoutineItem('😴 Sleep', routine['sleep'] ?? ''),
        _buildRoutineItem('🍽️ Diet', routine['diet'] ?? ''),
        _buildRoutineItem('🏃 Exercise', routine['exercise'] ?? ''),
        _buildRoutineItem('❤️ Mindset', routine['emotion'] ?? ''),
      ],
    );
  }

  Widget _buildRoutineItem(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SeasonsColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: SeasonsColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SeasonsTextStyles.body.copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(height: 4),
          Text(content, style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textSecondary)),
        ],
      ),
    );
  }

  List<Color> _getSeasonGradient(String season) {
    switch (season) {
      case 'spring': return [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)];
      case 'summer': return [const Color(0xFFFFCC02), const Color(0xFFFF9800)];
      case 'autumn': return [const Color(0xFFFFAB91), const Color(0xFFFF7043)];
      case 'winter': return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
      default: return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
    }
  }
}
