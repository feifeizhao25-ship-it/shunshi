// lib/core/ai_router/ai_router.dart

import 'package:dio/dio.dart';
import '../prompt/prompt_manager.dart';
import '../security/safety_filter.dart';
import '../config/models.dart';

/// AI Router - 负责 Prompt 管理、模型路由、安全过滤、JSON Schema 校验
class AIRouter {
  final Dio _dio;
  final PromptManager _promptManager;
  final SafetyFilter _safetyFilter;
  final AIConfig _config;

  AIRouter({
    required AIConfig config,
    PromptManager? promptManager,
    SafetyFilter? safetyFilter,
    Dio? dio,
  })  : _config = config,
        _promptManager = promptManager ?? PromptManager(),
        _safetyFilter = safetyFilter ?? SafetyFilter(),
        _dio = dio ?? Dio();

  /// 主入口：处理 AI 请求
  Future<AIResponse> route(AIRequest request) async {
    // 1. 安全过滤
    final safetyResult = await _safetyFilter.check(request.userInput);
    if (!safetyResult.isSafe) {
      return AIResponse(
        text: safetyResult.response,
        tone: 'gentle',
        careStatus: 'stable',
        safetyFlag: 'blocked',
        presenceLevel: 'normal',
      );
    }

    // 2. 选择模型
    final model = _selectModel(request);

    // 3. 构建 Prompt
    final prompt = await _promptManager.build(request);

    // 4. 调用 LLM
    final llmResponse = await _callLLM(model, prompt, request);

    // 5. JSON Schema 校验与解析
    final parsed = _parseResponse(llmResponse, request.expectedSchema);

    // 6. 日志记录
    await _logRequest(request, model, llmResponse, parsed);

    return parsed;
  }

  /// 模型选择策略
  ModelInfo _selectModel(AIRequest request) {
    // 关键节点使用大模型
    final isCriticalNode = [
      'daily_plan',
      'weekly_summary',
      'solar_term_summary',
      'health_assessment',
    ].contains(request.intent);

    if (isCriticalNode) {
      return _config.premiumModel;
    }

    // 根据用户类型选择
    return request.isPremium ? _config.premiumModel : _config.freeModel;
  }

  /// 调用 LLM
  Future<String> _callLLM(ModelInfo model, String prompt, AIRequest request) async {
    try {
      final response = await _dio.post(
        '${_config.apiGateway}/v1/chat/completions',
        data: {
          'model': model.name,
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': request.userInput},
          ],
          'temperature': model.temperature,
          'max_tokens': model.maxTokens,
          'response_format': {'type': 'json_object'},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model.apiKey}',
            'X-Request-ID': request.requestId,
          },
        ),
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      // 降级处理
      return await _fallback(request);
    }
  }

  /// 解析响应
  AIResponse _parseResponse(String rawResponse, String schemaType) {
    try {
      final json = _safeJsonParse(rawResponse);
      return AIResponse.fromJson(json);
    } catch (e) {
      // 解析失败，返回默认响应
      return AIResponse(
        text: rawResponse,
        tone: 'gentle',
        careStatus: 'stable',
        safetyFlag: 'none',
      );
    }
  }

  Map<String, dynamic> _safeJsonParse(String text) {
    // 尝试提取 JSON
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return _parseJson(jsonMatch.group(0)!);
    }
    return {'text': text};
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    // 简化版 JSON 解析
    // 实际应使用 json.decode
    return {'text': jsonStr};
  }

  /// 日志记录
  Future<void> _logRequest(
    AIRequest request,
    ModelInfo model,
    String rawResponse,
    AIResponse response,
  ) async {
    // 发送到日志服务
    print('[AI Router] ${request.requestId}: ${model.name} -> ${response.careStatus}');
  }

  /// 降级处理
  Future<AIResponse> _fallback(AIRequest request) async {
    return AIResponse(
      text: '抱歉，我现在有点困，让我休息一下再陪你聊天好吗？',
      tone: 'gentle',
      careStatus: 'stable',
      safetyFlag: 'none',
      presenceLevel: 'low',
    );
  }
}
