import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/network/api_service.dart';
import 'package:seasons/presentation/providers/chat_provider.dart';

void main() {
  group('ChatNotifier', () {
    late ApiService apiService;
    late ChatNotifier notifier;

    setUp(() {
      apiService = ApiService(baseUrl: 'http://localhost:8000');
      notifier = ChatNotifier(apiService);
    });

    test('initial state has empty messages', () {
      expect(notifier.state.messages, isEmpty);
    });

    test('initial state has null conversationId', () {
      expect(notifier.state.conversationId, isNull);
    });

    test('can be created with ApiService', () {
      expect(notifier, isNotNull);
    });
  });
}
