// test/unit/services/local_storage_test.dart
// TC-OFFLINE: 本地存储 + 离线队列测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/storage/local_storage.dart';

void main() {
  group('LocalStorage', () {
    test('TC-OFFLINE-010: LocalStorage is instantiable', () {
      final storage = LocalStorage();
      expect(storage, isNotNull);
    });

    test('TC-OFFLINE-010b: offline queue methods exist', () {
      final storage = LocalStorage();
      // Verify the API exists
      expect(storage.addToOfflineQueue, isA<Function>());
    });
  });
}
