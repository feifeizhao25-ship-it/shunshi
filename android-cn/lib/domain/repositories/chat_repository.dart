// lib/domain/repositories/chat_repository.dart
// 聊天仓储接口

import '../entities/message.dart';

abstract class ChatRepository {
  /// 发送消息并获取 AI 回复
  Future<Message> sendMessage({
    required String userId,
    required String userMessage,
    required String conversationId,
    Map<String, dynamic>? userContext,
  });

  /// 获取对话历史
  Future<List<Message>> getConversationHistory({
    required String userId,
    required String conversationId,
    int limit = 50,
  });

  /// 清空对话历史
  Future<void> clearHistory(String userId);

  /// 获取跟进提醒列表
  Future<List<Map<String, dynamic>>> getFollowUps(String userId);

  /// 关闭跟进提醒
  Future<void> dismissFollowUp(String followUpId);
}
