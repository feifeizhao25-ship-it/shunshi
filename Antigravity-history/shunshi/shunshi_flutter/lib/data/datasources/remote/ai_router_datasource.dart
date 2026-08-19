import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/ai_response.dart';
import '../../../domain/entities/solar_term.dart';
import '../../../domain/entities/user.dart';

/// AI Router 远端数据源 — ❌ 绝不直连模型 API
class AIRouterDatasource {
  final ApiClient _client;

  AIRouterDatasource(this._client);

  /// /chat/send
  Future<AIResponse> sendMessage({
    required String sessionId,
    required String message,
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.chatSend,
        data: {
          'session_id': sessionId,
          'message': message,
          'user_context': userContext.toJson(),
          'prompt_versions': promptVersions,
        },
        options: Options(
          receiveTimeout: ApiConstants.aiTimeout,
        ),
      );

      final data = response.data as Map<String, dynamic>;

      // 尝试严格 Schema 解析
      try {
        return AIResponse.fromJson(data);
      } on Exception catch (e) {
        Logger.warning('AI Response Schema parse failed, using fallback',
            error: e);
        final rawText = data['text'] as String? ?? data.toString();
        return AIResponse.fallback(rawText);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw const ServerException('AI 响应超时', statusCode: 408);
      }
      throw ServerException(
        e.message ?? 'AI Router 请求失败',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// /dailyPlan/generate
  Future<DailyPlan> generateDailyPlan({
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.dailyPlanGenerate,
        data: {
          'user_id': userContext.userId,
          'is_premium': userContext.isPremium,
          'constitution': userContext.memory.constitution,
          'solar_term': userContext.currentSolarTerm,
          'recent_mood': userContext.currentMood,
          'prompt_versions': promptVersions,
        },
        options: Options(
          receiveTimeout: ApiConstants.dailyPlanTimeout,
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return DailyPlan.fromJson(data);
    } on DioException catch (e) {
      Logger.warning('Daily plan request failed', error: e);
      throw ServerException(
        e.message ?? '每日计划生成失败',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 服务端收据验证
  Future<Map<String, dynamic>> verifyReceipt(String receipt) async {
    try {
      final response = await _client.post(
        ApiConstants.receiptVerify,
        data: {'receipt': receipt},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? '收据验证失败',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 获取用户权益
  Future<Map<String, dynamic>> getUserEntitlement() async {
    try {
      final response = await _client.get(ApiConstants.userEntitlement);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? '获取权益失败',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
