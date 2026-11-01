// 顺时 日记保存回归：客户端请求体必须符合后端 POST /api/v1/journal/entry 的契约（后端是准绳）。
//
// 后端 `JournalEntryRequest`：user_id 必填；mood / energy / sleep_quality 必填，1–5 整数；
// 备注叫 `notes`（≤1000）；`tags` 是字符串列表；`date` 可选 YYYY-MM-DD。
// 以前客户端发 `mood: '平和'`（字符串）、`note`，没有 energy / sleep_quality，后端 422，日记存不下来。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/data/network/journal_payload.dart';
import 'package:seasons/data/storage/storage_manager.dart';

String jwt(String sub) {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({'sub': sub, 'type': 'access'})}.sig';
}

/// 把后端 JournalEntryRequest 的校验规则逐条抄成这里的检查（后端文件见 backend/app/router/journal.py）。
List<String> contractViolations(Map<String, dynamic> body) {
  final bad = <String>[];
  if (body['user_id'] is! String || (body['user_id'] as String).isEmpty) bad.add('user_id 必填');
  for (final k in ['mood', 'energy', 'sleep_quality']) {
    final v = body[k];
    if (v is! int || v < 1 || v > 5) bad.add('$k 必须是 1–5 的整数，实际 ${jsonEncode(v)}');
  }
  if (body['notes'] != null && (body['notes'] is! String || (body['notes'] as String).length > 1000)) bad.add('notes 必须是 ≤1000 的字符串');
  if (body['tags'] != null && (body['tags'] is! List || (body['tags'] as List).any((t) => t is! String))) bad.add('tags 必须是字符串列表');
  if (body['date'] != null && !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(body['date'] as String)) bad.add('date 必须是 YYYY-MM-DD');
  return bad;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth_token': jwt('user-real-1')});
    await StorageManager.init();
  });

  test('保存请求体符合后端契约：心情是分数而不是文字，带 energy / sleep_quality / notes', () {
    final body = journalEntryBody(moodLabel: 'Calm', energy: 4, sleepQuality: 2, notes: '  今天还行  ');
    expect(contractViolations(body), isEmpty, reason: jsonEncode(body));
    expect(body['user_id'], 'user-real-1');
    expect(body['mood'], 4);
    expect(body['energy'], 4);
    expect(body['sleep_quality'], 2);
    expect(body['notes'], '今天还行');
    expect(body.containsKey('note'), isFalse, reason: '字段名是 notes，不是 note');
  });

  test('每个心情词都得到 1–5 的整数分，并作为标签带上原词', () {
    for (final m in ['Happy','Calm','Tired','Melancholy','Anxious','Angry']) {
      final body = journalEntryBody(moodLabel: m, energy: 3, sleepQuality: 3);
      expect(contractViolations(body), isEmpty, reason: '$m: ${jsonEncode(body)}');
      expect((body['tags'] as List).first, m);
    }
    expect(moodScore('Happy'), 5);
    expect(moodScore('Angry'), 1);
    expect(moodScore('???'), 3);
  });

  test('分数越界会被夹回 1–5（后端会对 0 或 6 返回 422）', () {
    final body = journalEntryBody(moodLabel: 'Calm', energy: 0, sleepQuality: 9);
    expect(body['energy'], 1);
    expect(body['sleep_quality'], 5);
    expect(contractViolations(body), isEmpty);
  });

  test('没写备注就不发 notes；不发 date 让服务端用它的「今天」', () {
    final body = journalEntryBody(moodLabel: 'Calm', energy: 3, sleepQuality: 3, notes: '   ');
    expect(body.containsKey('notes'), isFalse);
    expect(body.containsKey('date'), isFalse);
    expect(journalEntryBody(moodLabel: 'Calm', energy: 3, sleepQuality: 3, date: '2026-11-01')['date'], '2026-11-01');
  });

  test('旧请求体（复测里 422 的那种）会被契约检查拦住——证明这个测试能抓住原 bug', () {
    final old = <String, dynamic>{'user_id': 'user-real-1', 'mood': 'Calm', 'note': 'x', 'rituals': {'tea': true}};
    final bad = contractViolations(old);
    expect(bad.any((e) => e.startsWith('mood')), isTrue);
    expect(bad.any((e) => e.startsWith('energy')), isTrue);
    expect(bad.any((e) => e.startsWith('sleep_quality')), isTrue);
  });

  test('读回来：后端返回整数分 + date + notes，列表能还原心情词、日期和备注', () {
    final saved = {'entry_id': 'e1', 'date': '2026-11-01', 'mood': 4, 'energy': 3, 'sleep_quality': 3, 'notes': 'hi', 'tags': ['Calm', 'Tea']};
    expect(moodLabelOfEntry(saved, zh: false), 'Calm');
    expect(journalEntryDateLabel(saved), '11-01');
    expect(journalEntryHasNotes(saved), isTrue);
    // 没有标签（别的客户端写的）就按分数取词
    expect(moodLabelOfEntry({'mood': 5}, zh: false), 'Happy');
    expect(moodLabelOfEntry({'mood': 0}, zh: false), isNull);
    expect(journalEntryDateLabel({}), '');
    expect(journalEntryHasNotes({'notes': ''}), isFalse);
  });

  test('页面源码不再发字符串心情或 note 字段', () {
    final src = File('lib/presentation/pages/diary/diary_page_v2.dart').readAsStringSync();
    expect(src.contains("'mood': _selectedMood"), isFalse);
    expect(src.contains("'note': _noteController"), isFalse);
    expect(src.contains('journalEntryBody('), isTrue);
  });
}
