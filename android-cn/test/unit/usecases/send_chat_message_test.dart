// test/unit/usecases/send_chat_message_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shunshi/domain/entities/message.dart';
import 'package:shunshi/domain/repositories/chat_repository.dart';
import 'package:shunshi/domain/usecases/send_chat_message.dart';
import '../../fixtures/api_responses.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepo;
  late SendChatMessageUseCase useCase;

  setUp(() {
    mockRepo = MockChatRepository();
    useCase = SendChatMessageUseCase(mockRepo);
  });

  group('SendChatMessageUseCase', () {
    test('calls repository with correct parameters', () async {
      final expectedMsg = Message.fromJson(ApiFixtures.message);

      when(() => mockRepo.sendMessage(
        userId: any(named: 'userId'),
        userMessage: any(named: 'userMessage'),
        conversationId: any(named: 'conversationId'),
        userContext: any(named: 'userContext'),
      )).thenAnswer((_) async => expectedMsg);

      final result = await useCase(
        userId: 'user_001',
        userMessage: '今天立春，有什么养生建议？',
        conversationId: 'conv_001',
      );

      expect(result.id, expectedMsg.id);
      expect(result.content, isNotEmpty);
      verify(() => mockRepo.sendMessage(
        userId: 'user_001',
        userMessage: '今天立春，有什么养生建议？',
        conversationId: 'conv_001',
        userContext: null,
      )).called(1);
    });

    test('returns message with correct role', () async {
      final msg = Message.fromJson(ApiFixtures.message);
      when(() => mockRepo.sendMessage(
        userId: any(named: 'userId'),
        userMessage: any(named: 'userMessage'),
        conversationId: any(named: 'conversationId'),
        userContext: any(named: 'userContext'),
      )).thenAnswer((_) async => msg);

      final result = await useCase(
        userId: 'user_001',
        userMessage: '你好',
        conversationId: 'conv_001',
      );

      expect(result.isAssistant, isTrue);
    });
  });
}
