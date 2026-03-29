// lib/domain/usecases/send_chat_message.dart
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository _repository;
  SendChatMessageUseCase(this._repository);

  Future<Message> call({
    required String userId,
    required String userMessage,
    required String conversationId,
    Map<String, dynamic>? userContext,
  }) {
    return _repository.sendMessage(
      userId: userId,
      userMessage: userMessage,
      conversationId: conversationId,
      userContext: userContext,
    );
  }
}
