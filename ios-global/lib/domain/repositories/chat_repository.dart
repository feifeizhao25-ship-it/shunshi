// lib/domain/repositories/chat_repository.dart
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage({
    required String userId,
    required String userMessage,
    required String conversationId,
    Map<String, dynamic>? userContext,
  });
  Future<List<Message>> getConversationHistory({
    required String userId,
    required String conversationId,
    int limit = 50,
  });
  Future<void> clearHistory(String userId);
}
