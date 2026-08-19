import '../entities/ai_response.dart';
import '../entities/message.dart';
import '../entities/user.dart';
import '../repositories/chat_repository.dart';
import '../../core/utils/logger.dart';

/// 发送消息用例
class SendMessage {
  final ChatRepository _repository;

  SendMessage(this._repository);

  Future<AIResponse> execute({
    required String sessionId,
    required String message,
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    // 1. 保存用户消息到本地
    await _repository.saveMessageLocally(
      sessionId,
      Message.userMessage(message),
    );

    // 2. 发送到 AI Router
    final startTime = DateTime.now();
    final response = await _repository.sendMessage(
      sessionId: sessionId,
      message: message,
      userContext: userContext,
      promptVersions: promptVersions,
    );
    final latency = DateTime.now().difference(startTime).inMilliseconds;

    // 3. 审计日志
    Logger.aiCall(
      requestType: 'chat',
      model: response.metadata?.model ?? 'unknown',
      promptVersions: promptVersions,
      totalTokens: response.metadata?.tokens?.total ?? 0,
      latencyMs: latency,
      safetyFlag: response.safetyFlag.toJson(),
      userTier: userContext.isPremium ? 'premium' : 'free',
      schemaValid: response.metadata != null,
    );

    // 4. 保存 AI 回复到本地
    await _repository.saveMessageLocally(
      sessionId,
      response.toMessage(),
    );

    return response;
  }
}
