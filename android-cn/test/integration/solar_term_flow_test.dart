// test/integration/solar_term_flow_test.dart
// 节气流程集成测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import '../fixtures/api_responses.dart';

void main() {
  group('Solar Term Flow', () {
    test('获取当前节气', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);

      expect(term.isCurrent, isTrue);
      expect(term.name, '立春');
      expect(term.season, 'spring');
    });

    test('节气养生方案完整', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final plan = term.wellnessPlan!;

      expect(plan['diet'], isNotEmpty);
      expect(plan['tea'], isNotEmpty);
      expect(plan['exercise'], isNotEmpty);

      final diet = plan['diet'] as List;
      expect(diet.first['title'], isNotEmpty);
      expect(diet.first['description'], isNotEmpty);
    });

    test('多个节气切换', () {
      final lichun = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final lixia = SolarTerm.fromJson(ApiFixtures.solarTermLixia);

      expect(lichun.season, 'spring');
      expect(lixia.season, 'summer');
      expect(lichun.isCurrent, isTrue);
      expect(lixia.isCurrent, isFalse);
    });

    test('节气 copyWith 模拟切换当前节气', () {
      final current = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final previous = current.copyWith(isCurrent: false);
      final next = SolarTerm.fromJson(ApiFixtures.solarTermLixia).copyWith(isCurrent: true);

      expect(previous.isCurrent, isFalse);
      expect(next.isCurrent, isTrue);
    });
  });
}
