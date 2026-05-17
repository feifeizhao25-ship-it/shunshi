// ignore_for_file: unused_field, unused_import
/// Wellness Diary页 V3 — 接 API
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class DiaryPageV2 extends StatefulWidget {
  const DiaryPageV2({super.key});

  @override
  State<DiaryPageV2> createState() => _DiaryPageV2State();
}

class _DiaryPageV2State extends State<DiaryPageV2> {
  String? _userId;
  final _dio = apiClient.dio;
  final _noteController = TextEditingController();
  
  String _selectedMood = 'Calm';
  String _sleepTime = '22:45';
  String _wakeTime = '06:30';
  bool _teaDone = false;
  bool _meditationDone = false;
  bool _exerciseDone = false;
  bool _saving = false;
  bool _loading = false;

  List<Map<String, dynamic>> _recentEntries = [];
  String _aiInsight = '';

  static const _moods = ['Happy', 'Calm', 'Tired', 'Melancholy', 'Anxious', 'Angry'];
  static const _moodIcons = {
    'Happy': Icons.sentiment_satisfied,
    'Calm': Icons.yard,
    'Tired': Icons.bed,
    'Melancholy': Icons.cloud,
    'Anxious': Icons.flash_on,
    'Angry': Icons.local_fire_department,
  };

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final info = StorageManager.user.getUserInfo();
    _userId = info?['id'] as String? ?? 'guest';
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    try {
      final res = await _dio.get('/api/v1/journal/entries/user-001', queryParameters: {'user_id': _userId ?? 'guest', 'limit': 7});
      if (res.data is Map && res.data['entries'] is List) {
        _recentEntries = (res.data['entries'] as List).cast<Map<String, dynamic>>();
      }
      // Try trends for AI insight
      try {
        final trends = await _dio.get('/api/v1/journal/insights/${_userId ?? "guest"}');
        if (trends.data is Map && trends.data['insight'] != null) {
          _aiInsight = trends.data['insight'].toString();
        }
      } catch (_) {}
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveEntry() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _dio.post('/api/v1/journal/entry', data: {
        'user_id': _userId ?? 'guest',
        'mood': _selectedMood,
        'sleep_time': _sleepTime,
        'wake_time': _wakeTime,
        'note': _noteController.text.trim(),
        'rituals': {
          'tea': _teaDone,
          'meditation': _meditationDone,
          'exercise': _exerciseDone,
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('diary_diary_saved')), backgroundColor: ShunShiColors.primary),
        );
        _noteController.clear();
        _fetchEntries();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('diary_save_failed_please_retry')), backgroundColor: Colors.red.shade400),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final solarTerms = ['Minor Cold','Major Cold','Start of Spring','Rain Water','Awakening','Spring Equinox','Clear & Bright','Grain Rain','Start of Summer','Grain Buds','Grain in Ear','Summer Solstice','Minor Heat','Major Heat','Start of Autumn','End of Heat','White Dew','Autumn Equinox','Cold Dew','Frost Descent','Start of Winter','Minor Snow','Major Snow','Winter Solstice'];
    final termIdx = ((now.month - 1) * 2 + (now.day >= 6 ? 1 : 0)) % 24;
    
    return Scaffold(

    
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchEntries,
        color: ShunShiColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    Text(AppLocalizations.of(context).t('diary_wellness_diary'), style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 22, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
                    )),
                    const Spacer(),
                    Text('${now.month}/${now.day} · ${solarTerms[termIdx]}',
                      style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                  ]),
                ),
              ),
            ),

            // Quote
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(AppLocalizations.of(context).t('diary_follow_the_seasons_listen_to_your_body_rhythm'), style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 14, fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary,
                )),
              ),
            ),

            // Sleep Quality
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.bedtime, color: ShunShiColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).t('diary_sleep_quality'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildTimeInput('Bedtime', _sleepTime, (v) => setState(() => _sleepTime = v))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimeInput('Wake time', _wakeTime, (v) => setState(() => _wakeTime = v))),
                    ]),
                  ]),
                ),
              ),
            ),

            // Mood Map
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.self_improvement, color: ShunShiColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).t('diary_mood_map'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    ]),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: _moods.map((m) => GestureDetector(
                      onTap: () => setState(() => _selectedMood = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMood == m ? ShunShiColors.primary.withOpacity(0.1) : ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _selectedMood == m ? ShunShiColors.primary : Colors.transparent),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_moodIcons[m] ?? Icons.sentiment_neutral, size: 16, color: _selectedMood == m ? ShunShiColors.primary : ShunShiColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(m, style: TextStyle(fontSize: 13, color: _selectedMood == m ? ShunShiColors.primary : ShunShiColors.textTertiary, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    )).toList()),
                  ]),
                ),
              ),
            ),

            // Daily Rituals
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.done_all, color: ShunShiColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).t('diary_daily_rituals'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    ]),
                    const SizedBox(height: 14),
                    _buildRitualCheck(Icons.emoji_food_beverage, 'Tea', _teaDone, (v) => setState(() => _teaDone = v)),
                    _buildRitualCheck(Icons.air, 'Meditation', _meditationDone, (v) => setState(() => _meditationDone = v)),
                    _buildRitualCheck(Icons.directions_walk, 'Exercise', _exerciseDone, (v) => setState(() => _exerciseDone = v)),
                  ]),
                ),
              ),
            ),

            // 备注
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).t('diary_how_does_your_body_feel'),
                      hintStyle: TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary),
                  ),
                ),
              ),
            ),

            // 保存按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShunShiColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context).t('diary_save_diary'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ),

            // AI洞察
            if (_aiInsight.isNotEmpty) SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.smart_toy, color: Color(0xFFE4C285), size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).t('diary_ai_insights'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                    const SizedBox(height: 10),
                    Text(_aiInsight, style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.6)),
                  ]),
                ),
              ),
            ),

            // 历史记录
            if (_recentEntries.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(AppLocalizations.of(context).t('diary_recent_entries'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final e = _recentEntries[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(_moodIcons[e['mood']] ?? Icons.sentiment_neutral, color: ShunShiColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e['mood']?.toString() ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                          Text(e['created_at']?.toString().substring(5, 10) ?? '', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                        ])),
                        if (e['note'] != null) Icon(Icons.notes, color: ShunShiColors.textTertiary, size: 16),
                      ]),
                    ),
                  );
                }, childCount: _recentEntries.length),
              ),
            ],

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput(String label, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final parts = value.split(':');
            final time = await showTimePicker(context: context, 
              initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0));
            if (time != null) onChanged('${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}');
          },
          child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
        ),
      ]),
    );
  }

  Widget _buildRitualCheck(IconData icon, String label, bool done, ValueChanged<bool> onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => onToggle(!done),
        child: Row(children: [
          Icon(icon, color: ShunShiColors.primary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary)),
          const Spacer(),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? ShunShiColors.primary : Colors.transparent,
              border: Border.all(color: done ? ShunShiColors.primary : ShunShiColors.borderGhost),
            ),
            child: done ? Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}
