// test/unit/entities/solar_term_test.dart
// 太阳节气实体测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('SolarTerm entity', () {
    test('fromJson 解析完整数据', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);

      expect(term.id, 'solar_001');
      expect(term.name, '立春');
      expect(term.nameEn, 'Start of Spring');
      expect(term.emoji, '🌱');
      expect(term.season, 'spring');
      expect(term.date, '2月3日-5日');
      expect(term.description, contains('第一个节气'));
      expect(term.isCurrent, isTrue);
      expect(term.wellnessPlan, isNotNull);
      expect(term.wellnessPlan!['diet'], isA<List>());
    });

    test('fromJson 缺失字段使用默认值', () {
      final term = SolarTerm.fromJson({'name': '小寒'});

      expect(term.id, '小寒'); // fallback to name
      expect(term.nameEn, '');
      expect(term.emoji, '🌿');
      expect(term.season, 'spring');
      expect(term.isCurrent, isFalse);
    });

    test('copyWith 正确更新字段', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final updated = term.copyWith(
        name: '雨水',
        nameEn: 'Rain Water',
        isCurrent: false,
      );

      expect(updated.name, '雨水');
      expect(updated.nameEn, 'Rain Water');
      expect(updated.isCurrent, isFalse);
      // 不变的字段
      expect(updated.id, term.id);
      expect(updated.season, term.season);
    });

    test('立夏节气解析', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTermLixia);

      expect(term.name, '立夏');
      expect(term.season, 'summer');
      expect(term.isCurrent, isFalse);
      expect(term.wellnessPlan, isNull);
    });

    test('wellnessPlan 结构完整', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final plan = term.wellnessPlan!;

      expect(plan['diet'], isA<List>());
      expect(plan['tea'], isA<List>());
      expect(plan['exercise'], isA<List>());
      expect((plan['diet'] as List).length, 1);
      expect((plan['diet'] as List)[0]['title'], '韭菜炒鸡蛋');
    });
  });
}
