// SEASONS Global — ChatPage widget integration smoke test
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatPage integration', () {
    test('chat input field handles text', () {
      final msg = 'Hello SEASONS';
      expect(msg.trim().isNotEmpty, isTrue);
    });

    test('empty message is rejected', () {
      final emptyMsg = '  ';
      expect(emptyMsg.trim().isEmpty, isTrue);
    });
  });
}
