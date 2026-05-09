import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../design_system/theme.dart';

/// 日记页 — 横向日期选择 + 心情 + 标签 + 记录
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime _selectedDate = DateTime.now();
  int _mood = 2; // 0-4
  final _noteCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _saving = false;
  List<Map<String, dynamic>> _entries = [];

  static const _moodEmojis = ['😢', '😔', '😐', '😊', '😄'];
  static const _moodLabels = ['很差', '不好', '一般', '不错', '很好'];
  static const _tags = ['饮食', '运动', '睡眠', '情绪', '穴位'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  List<DateTime> get _last30Days {
    final now = DateTime.now();
    return List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'http://116.62.32.43:4000'));
      final res = await dio.get('/api/v1/journal/entries', queryParameters: {'user_id': userId});
      if (res.data is List) {
        setState(() => _entries = List<Map<String, dynamic>>.from(res.data));
        await prefs.setString('diary_entries', jsonEncode(res.data));
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('diary_entries');
      if (cached != null) {
        try { setState(() => _entries = List<Map<String, dynamic>>.from(jsonDecode(cached))); } catch (_) {}
      }
    }
  }

  Future<void> _save() async {
    if (_noteCtrl.text.trim().isEmpty && _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请写点什么或选择标签'), duration: Duration(seconds: 1)));
      return;
    }
    setState(() => _saving = true);
    final data = {
      'date': _selectedDate.toIso8601String().substring(0, 10),
      'mood': _mood + 1, // 1-5
      'note': _noteCtrl.text.trim(),
      'tags': _selectedTags.toList(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final dio = Dio(BaseOptions(baseUrl: 'http://116.62.32.43:4000'));
      await dio.post('/api/v1/journal/save', data: {...data, 'user_id': userId});
    } catch (_) {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      final local = List<Map<String, dynamic>>.from(
        (jsonDecode(prefs.getString('diary_entries') ?? '[]') as List).map((e) => Map<String, dynamic>.from(e as Map))
      );
      local.insert(0, data);
      await prefs.setString('diary_entries', jsonEncode(local));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)));
    }
    setState(() => _saving = false);
    _noteCtrl.clear();
    _selectedTags.clear();
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('养生日记',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        actions: [
          TextButton(
            onPressed: () => context.push('/diary-report'),
            child: const Text('周报', style: TextStyle(color: ShunShiColors.primary, fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal date picker
            _buildDatePicker(),
            const SizedBox(height: 24),

            // Mood selector
            const Text('今天心情如何？',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            _buildMoodSelector(),
            const SizedBox(height: 24),

            // Tags
            const Text('标签',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            _buildTags(),
            const SizedBox(height: 24),

            // Text input
            TextField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '记录今天的养生心得...',
                hintStyle: const TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: ShunShiColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  disabledBackgroundColor: ShunShiColors.textDisabled,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),

            // Recent entries
            const Text('最近记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('暂无记录', style: TextStyle(color: ShunShiColors.textTertiary))),
              )
            else
              ..._entries.take(10).map((e) => _buildEntryItem(e)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final dates = _last30Days;
    final today = DateTime.now();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final d = dates[index];
          final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
          final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = d),
            child: Container(
              width: 48,
              decoration: BoxDecoration(
                color: isSelected ? ShunShiColors.primary : ShunShiColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? ShunShiColors.primary : (isToday ? ShunShiColors.primary.withValues(alpha: 0.3) : ShunShiColors.borderGhost),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${d.month}/${d.day}',
                      style: TextStyle(fontSize: 10,
                          color: isSelected ? Colors.white70 : ShunShiColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text('${d.day}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : ShunShiColors.textPrimary)),
                  if (isToday && !isSelected)
                    Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: ShunShiColors.primary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final selected = _mood == i;
        return GestureDetector(
          onTap: () => setState(() => _mood = i),
          child: Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? ShunShiColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? ShunShiColors.primary : ShunShiColors.borderGhost,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(children: [
              Text(_moodEmojis[i], style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(_moodLabels[i], style: TextStyle(
                fontSize: 11,
                color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _tags.map((tag) {
        final selected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedTags.remove(tag);
            } else {
              _selectedTags.add(tag);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? ShunShiColors.primary.withValues(alpha: 0.08) : ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? ShunShiColors.primary : ShunShiColors.borderGhost,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? Icons.check_circle : Icons.label_outline,
                  size: 14, color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary),
              const SizedBox(width: 6),
              Text(tag, style: TextStyle(
                fontSize: 13,
                color: selected ? ShunShiColors.primary : ShunShiColors.textSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEntryItem(Map<String, dynamic> e) {
    final date = (e['date'] ?? e['created_at'] ?? '').toString().substring(0, 10);
    final mood = ((e['mood'] ?? 3) as num).toInt() - 1;
    final note = e['note'] ?? '';
    final tags = (e['tags'] as List?)?.cast<String>() ?? <String>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_moodEmojis[mood.clamp(0, 4)], style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(date, style: const TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: tags.map((t) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t, style: const TextStyle(fontSize: 11, color: ShunShiColors.primary)),
              ),
            ).toList()),
          ],
          if (note.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.toString(), style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ])),
      ]),
    );
  }
}
