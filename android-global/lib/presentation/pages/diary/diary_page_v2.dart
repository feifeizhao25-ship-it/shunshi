// ignore_for_file: unused_field, unused_import
/// Wellness Diary页 V3 — 接 API
library;

import '../../../core/solar_term/solar_term_en.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../design_system/theme.dart';
import '../../widgets/seasons_visual.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';
import '../../../data/network/session.dart';
import '../../../data/network/journal_payload.dart';
import 'journal_score_row.dart';

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
  // 后端要求精力、睡眠质量各是 1–5 分；和心情一样默认选中「3 一般」，用户可改。
  int _energy = 3;
  int _sleepQuality = 3;
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
    _userId = currentUserId();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    final uid = currentUserId();
    if (uid == null) {
      // 没有登录令牌就没有「我的日记」可取；不再用 user-001 / guest 去撞别人的数据。
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await _dio.get('/api/v1/journal/entries/${Uri.encodeComponent(uid)}', queryParameters: {'limit': 7});
      final entries = journalEntriesFromBody(res.data);
      if (entries != null) _recentEntries = entries;
      try {
        final insights = await _dio.get('/api/v1/journal/insights/${Uri.encodeComponent(uid)}');
        final text = journalInsightFromBody(insights.data);
        if (text != null) _aiInsight = text;
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveEntry() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _dio.post('/api/v1/journal/entry', data: journalEntryBody(
        moodLabel: _selectedMood,
        energy: _energy,
        sleepQuality: _sleepQuality,
        notes: _noteController.text,
        tags: [if (_teaDone) 'Tea', if (_meditationDone) 'Meditation', if (_exerciseDone) 'Exercise'],
      ));
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
    // 按天文节气表取当天节气（原来按“每月 6 日切换”估算，并且整体错位一格，10/16 会显示成 Frost Descent）
    final termName = currentSolarTermEn()?.$1 ?? '';
    
    return Scaffold(

    
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchEntries,
        color: ShunShiColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Season banner: photo, date and solar term
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SgHeroBanner(
                    asset: 'assets/images/sg_season_${sgSeasonFor(null)}.webp',
                    title: 'Wellness diary',
                    subtitle: '${now.month}/${now.day}${termName.isEmpty ? '' : ' · $termName'}  ·  Follow the seasons, listen to your body.',
                    height: 150,
                  ),
                ),
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
                    const SizedBox(height: 16),
                    JournalScoreRow(label: 'Sleep quality', value: _sleepQuality, onChanged: (v) => setState(() => _sleepQuality = v), activeColor: ShunShiColors.primary, textColor: ShunShiColors.textPrimary, lowHint: '1 poor', highHint: '5 great'),
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
                    const SizedBox(height: 16),
                    JournalScoreRow(label: 'Energy', value: _energy, onChanged: (v) => setState(() => _energy = v), activeColor: ShunShiColors.primary, textColor: ShunShiColors.textPrimary, lowHint: '1 drained', highHint: '5 energised'),
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
                    _buildRitualCheck('assets/images/wellness/tea_chamomile.jpg', 'Tea', 'Something warm and unhurried', _teaDone, (v) => setState(() => _teaDone = v)),
                    _buildRitualCheck('assets/images/wellness/emotion_meditation.jpg', 'Meditation', 'A few quiet minutes', _meditationDone, (v) => setState(() => _meditationDone = v)),
                    _buildRitualCheck('assets/images/wellness/exercise_morning_stretch.jpg', 'Exercise', 'Gentle movement', _exerciseDone, (v) => setState(() => _exerciseDone = v)),
                  ]),
                ),
              ),
            ),

            // Note
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

            // Save
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

            // AI insight
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

            // Recent entries
            if (_recentEntries.isEmpty && !_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: SgEmptyState(
                    asset: 'assets/images/sg_empty.webp',
                    title: 'No entries yet',
                    message: 'Save today\'s diary and it will show up here.',
                  ),
                ),
              ),
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
                        Icon(_moodIcons[moodLabelOfEntry(e, zh: false)] ?? Icons.sentiment_neutral, color: ShunShiColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(moodLabelOfEntry(e, zh: false) ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
                          Text(journalEntryDateLabel(e), style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                        ])),
                        if (journalEntryHasNotes(e)) Icon(Icons.notes, color: ShunShiColors.textTertiary, size: 16),
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

  Widget _buildRitualCheck(String photo, String label, String hint, bool done, ValueChanged<bool> onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => onToggle(!done),
        child: Row(children: [
          SgThumb(asset: photo, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              Text(hint, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            ]),
          ),
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
