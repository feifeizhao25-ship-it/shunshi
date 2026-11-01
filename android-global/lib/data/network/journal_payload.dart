/// 日记保存请求体 —— 与后端 `POST /api/v1/journal/entry`（`JournalEntryRequest`）逐字段对齐。
///
/// 后端是准绳：`mood` / `energy` / `sleep_quality` 都是必填的 1–5 整数，备注字段叫 `notes`，
/// 日期叫 `date`（YYYY-MM-DD），标签是字符串列表。以前客户端发的是 `mood: '平和'`（字符串）、
/// `note`，并且没有 `energy` / `sleep_quality`，后端一律 422，页面只弹「保存失败」，
/// 用户写的日记根本没存下来（顺时 日记保存）。
library;

import 'session.dart';

const Map<String, int> _zhMoodScores = {'开心': 5, '平和': 4, '疲劳': 3, '忧郁': 2, '焦虑': 2, '愤怒': 1};
const Map<String, int> _enMoodScores = {'Happy': 5, 'Calm': 4, 'Tired': 3, 'Melancholy': 2, 'Anxious': 2, 'Angry': 1};

/// 心情标签（中文或英文）对应的 1–5 分；不认识的标签按 3（一般）。
int moodScore(String label) => _zhMoodScores[label] ?? _enMoodScores[label] ?? 3;

int _clamp15(int v) => v < 1 ? 1 : (v > 5 ? 5 : v);

/// 构造保存日记的请求体。`tags` 里会带上心情标签本身，方便列表里还原成原来的词（分数是有损的）。
Map<String, dynamic> journalEntryBody({
  required String moodLabel,
  required int energy,
  required int sleepQuality,
  String notes = '',
  List<String> tags = const [],
  String? date,
}) {
  final text = notes.trim();
  return {
    ...userIdParam(),
    if (date != null) 'date': date, // 不传就由服务端按它的「今天」（Asia/Shanghai）记，避免跨时区时被判成未来日期
    'mood': moodScore(moodLabel),
    'energy': _clamp15(energy),
    'sleep_quality': _clamp15(sleepQuality),
    if (text.isNotEmpty) 'notes': text,
    'tags': [moodLabel, ...tags.where((t) => t != moodLabel)],
  };
}

/// 列表里一条日记的心情词：先看标签里存的原词，没有再按分数取该分数的第一个词。
String? moodLabelOfEntry(Map entry, {required bool zh}) {
  final table = zh ? _zhMoodScores : _enMoodScores;
  final tags = entry['tags'];
  if (tags is List) {
    for (final t in tags) {
      if (t is String && table.containsKey(t)) return t;
    }
  }
  final raw = entry['mood'];
  final score = raw is num ? raw.round() : int.tryParse('$raw');
  if (score == null) return null;
  for (final e in table.entries) {
    if (e.value == score) return e.key;
  }
  return null;
}

/// 列表里一条日记的日期（MM-DD）：后端给的是 `date`（YYYY-MM-DD），旧数据可能只有 `created_at` / `timestamp`。
String journalEntryDateLabel(Map entry) {
  for (final k in ['date', 'timestamp', 'created_at', 'entry_date']) {
    final v = entry[k]?.toString() ?? '';
    if (v.length >= 10) return v.substring(5, 10);
  }
  return '';
}

/// 这条日记有没有备注（后端字段是 `notes`，旧字段 `note` 也认）。
bool journalEntryHasNotes(Map entry) {
  for (final k in ['notes', 'note']) {
    final v = entry[k];
    if (v is String && v.trim().isNotEmpty) return true;
  }
  return false;
}
