// SEASONS Global — SendChatMessage use case unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/domain/entities/entities.dart';
import 'package:seasons/domain/repositories/chat_repository.dart';
import 'package:seasons/domain/usecases/send_chat_message.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  group('SendChatMessage', () {
    late MockChatRepository mockChatRepository;
    late SendChatMessage useCase;

    setUp(() {
      mockChatRepository = MockChatRepository();
      useCase = SendChatMessage(mockChatRepository);
    });

    test('returns message on success', () async {
      final testMessage = Message(
        id: 'msg1',
        content: 'Hello',
        role: MessageRole.assistant,
      );

      when(
        () => mockChatRepository.sendMessage('user1', 'Hello'),
      ).thenAnswer((_) async => testMessage);

      final result = await useCase.call('user1', 'Hello');

      expect(result, equals(testMessage));
      expect(result.id, equals('msg1'));
      expect(result.content, equals('Hello'));
      verify(
        () => mockChatRepository.sendMessage('user1', 'Hello'),
      ).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        () => mockChatRepository.sendMessage('user1', 'Hello'),
      ).thenThrow(Exception('Network error'));

      expect(
        () => useCase.call('user1', 'Hello'),
        throwsException,
      );
    });
  });
}
