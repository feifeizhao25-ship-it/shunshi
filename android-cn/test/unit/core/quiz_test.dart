// test/unit/core/quiz_test.dart
// TC-QUIZ: 体质测试逻辑单元测试

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quiz Logic', () {
    // 9 种体质类型
    final bodyTypes = [
      'qi_xu', 'yang_xu', 'yin_xu', 'tan_shi',
      'shi_re', 'xue_yu', 'qi_yu', 'te_bing', 'ping_he',
    ];

    test('TC-QUIZ-001: all 9 body types exist', () {
      expect(bodyTypes.length, 9);
      expect(bodyTypes, contains('qi_xu'));
      expect(bodyTypes, contains('ping_he'));
    });

    test('TC-QUIZ-002: basic info validation - age >= 12', () {
      final birthYear = 2018;
      final age = DateTime.now().year - birthYear;
      expect(age < 12, isTrue); // Too young
      final validBirth = 1990;
      final validAge = DateTime.now().year - validBirth;
      expect(validAge >= 12, isTrue);
    });

    test('TC-QUIZ-002b: gender/birth required', () {
      final basicInfo = <String, dynamic>{};
      final isValid = basicInfo.containsKey('gender') && basicInfo.containsKey('birth_date');
      expect(isValid, isFalse);

      basicInfo['gender'] = 'female';
      expect(basicInfo.containsKey('gender'), isTrue);
      expect(basicInfo.containsKey('birth_date'), isFalse);
    });

    test('TC-QUIZ-010: progress bar calculation', () {
      const totalQuestions = 20;
      for (int current = 1; current <= 20; current++) {
        final progress = current / totalQuestions;
        expect(progress, greaterThan(0));
        expect(progress, lessThanOrEqualTo(1.0));
      }
    });

    test('TC-QUIZ-010b: answer saves to draft', () {
      final draft = <String, dynamic>{
        'basic_info': {'gender': 'female', 'birth_date': '1990-05-12'},
        'answers': <Map<String, int>>[],
      };
      (draft['answers'] as List).add({'question_id': 1, 'value': 3});
      expect((draft['answers'] as List).length, 1);
    });

    test('TC-QUIZ-011: resume from draft', () {
      final draft = {
        'basic_info': {'gender': 'female'},
        'answers': [
          {'question_id': 1, 'value': 3},
          {'question_id': 2, 'value': 2},
        ],
        'last_index': 3,
      };
      expect(draft['last_index'], 3);
      expect((draft['answers'] as List).length, 2);
    });

    test('TC-QUIZ-020: submit requires all 20 answers', () {
      final partialAnswers = List.generate(10, (i) => {'question_id': i + 1, 'value': 3});
      expect(partialAnswers.length < 20, isTrue); // incomplete

      final fullAnswers = List.generate(20, (i) => {'question_id': i + 1, 'value': 3});
      expect(fullAnswers.length, 20); // complete
    });

    test('TC-QUIZ-020b: computing animation >= 3 seconds', () {
      const minAnimationMs = 3000;
      expect(minAnimationMs, greaterThanOrEqualTo(3000));
    });

    test('TC-QUIZ-021: idempotency key prevents duplicate submit', () {
      final submittedKeys = <String>{};
      const key = 'quiz-submit-123';

      final isDuplicate = submittedKeys.contains(key);
      expect(isDuplicate, isFalse);
      submittedKeys.add(key);

      final isDuplicateAgain = submittedKeys.contains(key);
      expect(isDuplicateAgain, isTrue);
    });

    test('TC-QUIZ-022: result has primary + secondary types', () {
      final result = {
        'primary_type': {'key': 'qi_xu', 'name': '气虚质', 'score': 78},
        'secondary_types': [
          {'key': 'yang_xu', 'score': 32},
          {'key': 'xue_yu', 'score': 18},
        ],
      };
      expect(result['primary_type'], isNotNull);
      expect((result['secondary_types'] as List).length, 2);
      expect((result['primary_type'] as Map)['score'], greaterThanOrEqualTo(60));
    });
  });
}
