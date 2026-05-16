// test/unit/services/safety_filter_test.dart
// 安全过滤器单元测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/security/safety_filter.dart';

void main() {
  late SafetyFilter filter;

  setUp(() {
    filter = SafetyFilter();
  });

  group('SafetyFilter', () {
    group('正常输入', () {
      test('普通养生问题通过', () async {
        final result = await filter.check('今天适合吃什么？');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'none');
        expect(result.response, isEmpty);
        expect(result.needsDoctorConsult, isFalse);
      });

      test('节气相关提问通过', () async {
        final result = await filter.check('立春应该怎么养生？');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'none');
      });

      test('情绪正常表达通过', () async {
        final result = await filter.check('今天心情不错');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'none');
      });

      test('体质相关问题通过', () async {
        final result = await filter.check('我是气虚体质，适合喝什么茶？');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'none');
      });

      test('空字符串通过', () async {
        final result = await filter.check('');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'none');
      });
    });

    group('敏感词检测', () {
      test('自杀关键词触发拦截', () async {
        final result = await filter.check('我想自杀');
        expect(result.isSafe, isFalse);
        expect(result.flag, 'sensitive');
        expect(result.response, contains('400-161-9995'));
      });

      test('自残关键词触发拦截', () async {
        final result = await filter.check('我想自残');
        expect(result.isSafe, isFalse);
        expect(result.flag, 'sensitive');
        expect(result.response, isNotEmpty);
      });

      test('敏感词嵌入长句也能检测', () async {
        final result = await filter.check('最近压力很大，有时候会想自杀算了');
        expect(result.isSafe, isFalse);
        expect(result.flag, 'sensitive');
      });
    });

    group('医疗关键词检测', () {
      test('诊断关键词标记为需就医', () async {
        final result = await filter.check('帮我诊断一下');
        expect(result.isSafe, isTrue); // 不拦截
        expect(result.flag, 'caution');
        expect(result.needsDoctorConsult, isTrue);
      });

      test('吃药问题标记为需就医', () async {
        final result = await filter.check('我该吃什么药？');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'caution');
        expect(result.needsDoctorConsult, isTrue);
      });

      test('治疗问题标记为需就医', () async {
        final result = await filter.check('怎么治疗感冒？');
        expect(result.isSafe, isTrue);
        expect(result.flag, 'caution');
        expect(result.needsDoctorConsult, isTrue);
      });

      test('血压关键词标记为需就医', () async {
        final result = await filter.check('我血压偏高怎么办');
        expect(result.flag, 'caution');
        expect(result.needsDoctorConsult, isTrue);
      });

      test('肿瘤关键词标记为需就医', () async {
        final result = await filter.check('体检发现肿瘤指标偏高');
        expect(result.flag, 'caution');
        expect(result.needsDoctorConsult, isTrue);
      });
    });

    group('优先级', () {
      test('敏感词优先于医疗词', () async {
        // 同时包含"治疗"和"自杀"
        final result = await filter.check('我想自杀，怎么治疗都没用');
        expect(result.isSafe, isFalse);
        expect(result.flag, 'sensitive');
      });
    });
  });
}
