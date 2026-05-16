// test/integration/constitution_flow_test.dart
// 体质测评流程集成测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/user.dart';
import '../fixtures/api_responses.dart';

void main() {
  group('Constitution Flow', () {
    test('获取体质问卷', () {
      final response = ApiFixtures.constitutionQuestionsResponse;

      expect(response['total'], 25);
      final questions = response['questions'] as List;
      expect(questions.length, 2);

      final q1 = questions[0] as Map<String, dynamic>;
      expect(q1['text'], isNotEmpty);
      expect(q1['options'], isA<List>());
      expect((q1['options'] as List).length, 3);
    });

    test('测评结果 — 平和质', () {
      final user = User.fromJson(ApiFixtures.user);
      expect(user.constitution, ConstitutionType.balanced);
      expect(user.constitutionName, '平和质');
    });

    test('测评结果 — 气虚质', () {
      final user = User.fromJson(ApiFixtures.userPremium);
      expect(user.constitution, ConstitutionType.qiDeficiency);
      expect(user.constitutionName, '气虚质');
    });

    test('测评结果 — 阴虚质（南半球用户）', () {
      final user = User.fromJson(ApiFixtures.userFamily);
      expect(user.constitution, ConstitutionType.yinDeficiency);
      expect(user.hemisphere, 'south');
    });

    test('9种体质类型全覆盖', () {
      final types = ConstitutionType.values.where((t) => t != ConstitutionType.unknown);
      expect(types.length, 9);
    });

    test('未测评用户为 unknown', () {
      final user = User.fromJson(
        (ApiFixtures.guestLoginResponse['user'] as Map<String, dynamic>),
      );
      expect(user.constitution, ConstitutionType.unknown);
      expect(user.constitutionName, '未识别');
    });
  });
}
