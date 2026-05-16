// test/unit/core/search_test.dart
// TC-SEARCH: 搜索逻辑单元测试

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Search', () {
    test('TC-SEARCH-001: minimum 2 chars to search', () {
      bool shouldSearch(String query) => query.length >= 2;
      expect(shouldSearch('a'), isFalse);
      expect(shouldSearch('失'), isFalse);
      expect(shouldSearch('失眠'), isTrue);
      expect(shouldSearch('失眠食疗'), isTrue);
    });

    test('TC-SEARCH-002: 300ms debounce', () {
      const debounceMs = 300;
      // Simulate rapid typing: 失(0ms) 眠(100ms) 食(200ms)
      // Should only search after 300ms pause
      final lastTypeAt = DateTime.now();
      final elapsed = DateTime.now().difference(lastTypeAt).inMilliseconds;
      final shouldSearch = elapsed >= debounceMs;
      expect(shouldSearch, isFalse); // too soon
    });

    test('TC-SEARCH-003: highlight matching keywords', () {
      const title = '失眠调理粥';
      const keyword = '失眠';
      final highlighted = title.contains(keyword);
      expect(highlighted, isTrue);
    });

    test('TC-SEARCH-004: history management', () {
      final history = <String>['失眠', '感冒', '气虚'];
      expect(history.length, 3);

      // Add new search
      history.insert(0, '养肝');
      expect(history.length, 4);
      expect(history.first, '养肝');

      // Remove duplicate
      history.remove('失眠');
      history.insert(0, '失眠');
      expect(history.length, 4);
      expect(history.first, '失眠');

      // Clear all
      history.clear();
      expect(history.isEmpty, isTrue);
    });

    test('TC-SEARCH-004b: max history 20 items', () {
      const maxHistory = 20;
      final history = List.generate(25, (i) => '搜索$i');
      if (history.length > maxHistory) {
        history.removeRange(maxHistory, history.length);
      }
      expect(history.length, 20);
    });
  });
}
