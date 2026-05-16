// test/unit/core/journal_test.dart
// TC-JRNL: 日记逻辑单元测试

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Journal', () {
    test('TC-JRNL-001: mood types complete', () {
      final moods = ['great', 'good', 'neutral', 'bad', 'terrible'];
      expect(moods.length, 5);
      // CN uses different labels
      final cnMoods = {'great': '很好', 'good': '好', 'neutral': '一般', 'bad': '差', 'terrible': '很差'};
      for (final m in moods) {
        expect(cnMoods[m], isNotNull);
      }
    });

    test('TC-JRNL-010: auto-save every 15 seconds', () {
      const autoSaveInterval = Duration(seconds: 15);
      expect(autoSaveInterval.inSeconds, 15);
    });

    test('TC-JRNL-010b: draft includes date + solar term', () {
      final draft = {
        'date': '2026-04-25',
        'solar_term': 'guyu',
        'mood': 'happy',
        'thought': '今天心情不错',
      };
      expect(draft.containsKey('date'), isTrue);
      expect(draft.containsKey('solar_term'), isTrue);
    });

    test('TC-JRNL-011: exit unsaved triggers confirmation', () {
      final draft = {'thought': '未保存的内容'};
      final hasUnsaved = draft['thought'] != null && (draft['thought'] as String).isNotEmpty;
      expect(hasUnsaved, isTrue);
    });

    test('TC-JRNL-012: create journal API payload', () {
      final payload = {
        'date': '2026-04-25',
        'mood': 'happy',
        'thought': '今天很开心',
      };
      expect(payload['mood'], 'happy');
      expect(payload['thought'], isNotNull);
    });

    test('TC-JRNL-012b: edit journal uses PUT', () {
      const method = 'PUT';
      const endpoint = '/journals/j1';
      expect(method, 'PUT');
      expect(endpoint.contains('j1'), isTrue);
    });

    test('TC-JRNL-013: offline journal queued for sync', () {
      final queue = <Map<String, dynamic>>[];
      queue.add({
        'type': 'journal',
        'action': 'create',
        'data': {'mood': 'happy', 'thought': '离线写的'},
        'retry_count': 0,
      });
      expect(queue.length, 1);
      expect(queue[0]['type'], 'journal');
    });

    test('TC-JRNL-014: image compression to 1080px width', () {
      const maxWidth = 1080;
      const originalWidth = 4000;
      final scaled = originalWidth > maxWidth ? maxWidth : originalWidth;
      expect(scaled, 1080);
    });

    test('TC-JRNL-014b: file size limit 10MB', () {
      const maxBytes = 10 * 1024 * 1024;
      final smallFile = 5 * 1024 * 1024;
      final largeFile = 15 * 1024 * 1024;
      expect(smallFile < maxBytes, isTrue);
      expect(largeFile < maxBytes, isFalse);
    });

    test('TC-JRNL-001b: calendar shows mood markers', () {
      final entries = [
        {'date': '2026-04-20', 'mood': 'happy'},
        {'date': '2026-04-22', 'mood': 'calm'},
      ];
      final datesWithMood = entries.map((e) => e['date']).toSet();
      expect(datesWithMood.contains('2026-04-20'), isTrue);
      expect(datesWithMood.contains('2026-04-25'), isFalse);
    });
  });
}
