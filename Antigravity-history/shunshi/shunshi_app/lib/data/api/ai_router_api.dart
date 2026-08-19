import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/ai_response.dart';
import '../models/user_context.dart';

/// AI Router API 协议实现
/// POST /chat/send
/// POST /dailyPlan/generate
class AiRouterApi {
  final ApiClient _client;

  AiRouterApi({required ApiClient client}) : _client = client;

  /// 发送聊天消息
  /// 严格遵守 AI Router 协议
  Future<AiResponse> sendMessage({
    required String userId,
    required UserContext context,
    required String message,
    bool isPremium = false,
  }) async {
    final promptVersion = isPremium
        ? const PromptVersion.premiumChat()
        : const PromptVersion();
    try {
      final response = await _client.post('/chat/send', data: {
        'user_id': userId,
        'context': context.toApiContext(),
        'message': message,
        'prompt_version': promptVersion.toJson(),
      });
      return AiResponse.safeParse(response.data);
    } on DioException catch (e) {
      // 网络降级
      return AiResponse.degraded(_extractErrorMessage(e));
    } catch (e) {
      return AiResponse.degraded('');
    }
  }

  /// 生成每日计划
  Future<AiResponse> generateDailyPlan({
    required String userId,
    required UserContext context,
    bool isPremium = false,
  }) async {
    final promptVersion = isPremium
        ? const PromptVersion.premiumDailyPlan()
        : const PromptVersion.dailyPlan();
    try {
      final response = await _client.post('/dailyPlan/generate', data: {
        'user_id': userId,
        'context': context.toApiContext(),
        'prompt_version': promptVersion.toJson(),
      });
      return AiResponse.safeParse(response.data);
    } on DioException catch (e) {
      return AiResponse.degraded(_extractErrorMessage(e));
    } catch (e) {
      return AiResponse.degraded('');
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '网络连接超时，请稍后再试。';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络状态。';
    }
    return '';
  }
}
