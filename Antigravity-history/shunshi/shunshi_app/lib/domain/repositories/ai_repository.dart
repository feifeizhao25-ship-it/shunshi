import '../../data/models/ai_response.dart';
import '../../data/models/message.dart';
import '../../data/models/user_context.dart';

abstract class AiRepository {
  /// 发送聊天消息，返回 AI 响应（严格 Schema）
  Future<AiResponse> sendMessage({
    required String userId,
    required UserContext context,
    required String message,
  });

  /// 生成今日计划
  Future<AiResponse> generateDailyPlan({
    required String userId,
    required UserContext context,
  });

  /// 获取聊天历史
  Future<List<Message>> getChatHistory({required String userId, int limit = 50});

  /// 保存消息
  Future<void> saveMessage(String userId, Message message);

  /// 清空记忆（符合记忆可控要求）
  Future<void> clearMemory(String userId);
}
