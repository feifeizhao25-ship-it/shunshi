// lib/core/ai_router/shunshi_router.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/models.dart';
import '../prompt/prompt_builder.dart' show PromptBuilder, PromptBuildResult, UserContext;
import '../prompt/task_prompts.dart' show TaskType;
import '../security/safety_filter.dart';

/// SEASONS AI Router - 生产级实现
/// 
/// 职责：
/// 1. Prompt 组合管理
/// 2. 模型路由选择
/// 3. 安全过滤
/// 4. Schema 校验
/// 5. th志Records
/// 6. Token 统计
class ShunShiRouter {
  final Dio _dio;
  final SafetyFilter _safetyFilter;
  final RouterConfig _config;

  // 统计
  int _totalRequests = 0;
  int _totalTokens = 0;
  final Map<String, int> _modelUsage = {};

  ShunShiRouter({
    required RouterConfig config,
    Dio? dio,
    SafetyFilter? safetyFilter,
  })  : _config = config,
        _dio = dio ?? Dio(),
        _safetyFilter = safetyFilter ?? SafetyFilter();

  /// 主入口：处理 AI 请求
  Future<AIResponse> route(AIRequest request) async {
    final startTime = DateTime.now();

    try {
      // 1. 安全检查
      final safetyResult = await _safetyFilter.check(request.userMessage ?? request.userInput);
      if (!safetyResult.isSafe) {
        return _buildSafetyResponse(safetyResult);
      }

      // 2. 构建 Prompt
      final taskType = TaskType.values.firstWhere(
        (e) => e.name == (request.intent ?? 'chat'),
        orElse: () => TaskType.chat,
      );
      final promptResult = PromptBuilder.build(
        userId: request.userId,
        taskType: taskType,
        userMessage: request.userMessage ?? request.userInput,
        userContext: UserContext(userId: request.userId),
      );

      // 3. 调用 LLM
      final llmResponse = await _callLLM(
        promptResult.model,
        promptResult.prompt,
        request,
      );

      // 4. 解析响应
      final parsedResponse = _parseResponse(llmResponse, taskType);

      // 5. 统计
      _recordStats(promptResult, startTime);

      // 6. th志
      await _logRequest(request, promptResult, llmResponse, parsedResponse);

      return parsedResponse;
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  /// 调用 LLM
  Future<String> _callLLM(
    ModelInfo model,
    String prompt,
    AIRequest request,
  ) async {
    final response = await _dio.post(
      '${_config.apiBaseUrl}/api/v1/chat/completions',
      data: {
        'model': model.name,
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': request.userMessage ?? request.userInput},
        ],
        'temperature': model.temperature,
        'max_tokens': model.maxTokens,
        'response_format': {'type': 'json_object'},
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_config.apiKey}',
          'Content-Type': 'application/json',
          'X-Request-ID': request.requestId,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return response.data['choices'][0]['message']['content'] ?? '';
  }

  /// 解析响应
  AIResponse _parseResponse(String rawResponse, TaskType taskType) {
    try {
      // 提取 JSON
      final jsonStr = _extractJson(rawResponse);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return AIResponse.fromJson(json);
    } catch (e) {
      // 解析失败，Back兜底响应
      return AIResponse(
        text: _sanitizeText(rawResponse),
        tone: 'gentle',
        careStatus: 'stable',
        safetyFlag: 'none',
      );
    }
  }

  /// 提取 JSON
  String _extractJson(String text) {
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }
    return '{"text": "$text"}';
  }

  /// 清理文本
  String _sanitizeText(String text) {
    // 移除可能的 markdown 代码块
    return text
        .replaceAll(RegExp(r'^```json'), '')
        .replaceAll(RegExp(r'^```'), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();
  }

  /// 构建安全响应
  AIResponse _buildSafetyResponse(SafetyResult result) {
    return AIResponse(
      text: result.response.isNotEmpty
          ? result.response
          : 'I understand your concerns. For this, I recommend consulting a professional doctor.',
      tone: 'gentle',
      careStatus: result.needsDoctorConsult ? 'concerned' : 'stable',
      safetyFlag: result.flag,
      presenceLevel: 'low',
    );
  }

  /// 构建错误响应
  AIResponse _buildErrorResponse(dynamic error) {
    return AIResponse(
      text: 'Sorry, I\'m a bit tired now. Let me rest and chat with you later.',
      tone: 'gentle',
      careStatus: 'stable',
      safetyFlag: 'none',
      presenceLevel: 'low',
    );
  }

  /// Records统计
  void _recordStats(PromptBuildResult promptResult, DateTime startTime) {
    _totalRequests++;
    _totalTokens += promptResult.estimatedTokens;
    _modelUsage[promptResult.model.name] =
        (_modelUsage[promptResult.model.name] ?? 0) + 1;
  }

  /// th志Records
  Future<void> _logRequest(
    AIRequest request,
    PromptBuildResult promptResult,
    String rawResponse,
    AIResponse response,
  ) async {
    // Send到th志服务
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'requestId': request.requestId,
      'userId': request.userId,
      'taskType': request.intent ?? 'chat',
      'model': promptResult.model.name,
      'tokens': promptResult.estimatedTokens,
      'latencyMs': DateTime.now().difference(DateTime.now()).inMilliseconds,
      'careStatus': response.careStatus,
      'safetyFlag': response.safetyFlag,
    };

    print('[ShunShi Router] ${jsonEncode(log)}');
  }

  /// 获取统计信息
  RouterStats getStats() {
    return RouterStats(
      totalRequests: _totalRequests,
      totalTokens: _totalTokens,
      modelUsage: _modelUsage,
    );
  }
}

/// Router 配置
class RouterConfig {
  final String apiBaseUrl;
  final String apiKey;
  final String freeModel;
  final String premiumModel;

  RouterConfig({
    required this.apiBaseUrl,
    required this.apiKey,
    this.freeModel = 'qwen2.5-7b-instruct',
    this.premiumModel = 'qwen2.5-72b-instruct',
  });
}

/// Router 统计
class RouterStats {
  final int totalRequests;
  final int totalTokens;
  final Map<String, int> modelUsage;

  RouterStats({
    required this.totalRequests,
    required this.totalTokens,
    required this.modelUsage,
  });
}
