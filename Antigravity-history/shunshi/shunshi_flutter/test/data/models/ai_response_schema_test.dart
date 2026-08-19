import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi_flutter/domain/entities/ai_response.dart';
import 'package:shunshi_flutter/domain/entities/care_status.dart';

/// 加载 JSON fixture
Map<String, dynamic> loadFixture(String path) {
  final file = File('test/fixtures/$path');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('AIResponse Schema 回归测试', () {
    test('解析 free/chat_normal 应返回 green', () {
      final json = loadFixture('ai_response/free/chat_normal.json');
      final response = AIResponse.fromJson(json);
      expect(response.safetyFlag, SafetyFlag.green);
      expect(response.text, isNotEmpty);
      expect(response.careStatus, CareStatus.stable);
      expect(response.followUpQuestions, isNotEmpty);
    });

    test('解析 premium/chat_deep_context 应含 metadata + follow_up', () {
      final json = loadFixture('ai_response/premium/chat_deep_context.json');
      final response = AIResponse.fromJson(json);
      expect(response.safetyFlag, SafetyFlag.green);
      expect(response.careStatus, CareStatus.needsAttention);
      expect(response.followUp, isNotNull);
      expect(response.followUp!.inDays, 3);
      expect(response.followUp!.intent, 'mood_check');
      expect(response.contentCards, isNotEmpty);
      expect(response.metadata, isNotNull);
      expect(response.metadata!.model, 'qwen2.5-72b-instruct');
    });

    test('解析 abnormal/safety_red 应返回 red + escalate', () {
      final json = loadFixture('ai_response/abnormal/safety_red.json');
      final response = AIResponse.fromJson(json);
      expect(response.safetyFlag, SafetyFlag.red);
      expect(response.safetyFlag.requiresSafeMode, true);
      expect(response.careStatus, CareStatus.escalate);
      expect(response.offlineEncouraged, true);
      expect(response.followUpQuestions, isEmpty);
    });

    test('解析 malformed/missing_fields 应 fallback 但不崩溃', () {
      final json = loadFixture('ai_response/malformed/missing_fields.json');
      final response = AIResponse.fromJson(json);
      // text 缺失应为空字符串
      expect(response.text, isEmpty);
      expect(response.tone, 'warm');
      expect(response.safetyFlag, SafetyFlag.green); // 默认
    });

    test('AIResponse.fallback 应提供安全默认值', () {
      final response = AIResponse.fallback('raw text content');
      expect(response.text, 'raw text content');
      expect(response.safetyFlag, SafetyFlag.green);
      expect(response.tone, 'warm');
      expect(response.careStatus, CareStatus.stable);
      expect(response.presenceLevel, PresenceLevel.normal);
      expect(response.contentCards, isEmpty);
    });
  });
}
