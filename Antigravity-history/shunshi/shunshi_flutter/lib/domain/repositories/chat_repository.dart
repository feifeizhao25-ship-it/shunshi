import '../entities/ai_response.dart';
import '../entities/message.dart';
import '../entities/user.dart';
import '../entities/solar_term.dart';

/// 聊天仓库抽象
abstract class ChatRepository {
  /// 发送消息到 AI Router
  Future<AIResponse> sendMessage({
    required String sessionId,
    required String message,
    required UserContext userContext,
    required Map<String, String> promptVersions,
  });

  /// 生成每日计划
  Future<DailyPlan> generateDailyPlan({
    required UserContext userContext,
    required Map<String, String> promptVersions,
  });

  /// 获取会话列表
  Future<List<Conversation>> getConversations();

  /// 获取会话消息
  Future<List<Message>> getMessages(String sessionId);

  /// 创建新会话
  Future<Conversation> createConversation();

  /// 保存消息到本地
  Future<void> saveMessageLocally(String sessionId, Message message);
}
