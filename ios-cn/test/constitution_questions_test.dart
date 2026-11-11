import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/constitution/constitution_questions.dart';
import 'package:shunshi/presentation/pages/constitution/constitution_test_v2.dart';

const backendBody = {
  'success': true,
  'data': {
    'questions': [
      {
        'id': 1,
        'question': '您精力充沛吗？',
        'options': [
          {'text': '是', 'value': '是'},
          {'text': '有时是', 'value': '有时是'},
          {'text': '否', 'value': '否'},
        ],
      },
    ],
    'total': 1,
  },
};

void main() {
  test('quiz path is the constitution router, not /questions', () {
    expect(kConstitutionQuestionsPath, '/api/v1/constitution/questions');
  });

  test('wrapped backend payload parses option objects', () {
    final questions = parseConstitutionQuestions(backendBody);
    expect(questions, hasLength(1));
    expect(questions.first['id'], 1);
    expect(questions.first['question'], '您精力充沛吗？');
    expect(questions.first['options'], ['是', '有时是', '否']);
  });

  test('an empty questions object does not invent a list', () {
    expect(parseConstitutionQuestions({'success': true, 'data': {'questions': []}}), isEmpty);
    expect(parseConstitutionQuestions({'questions': 'nope'}), isEmpty);
  });

  testWidgets('parsed backend questions replace 暂无题目', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConstitutionTestV2(loadQuestions: () async => parseConstitutionQuestions(backendBody)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('暂无题目'), findsNothing);
    expect(find.text('您精力充沛吗？'), findsOneWidget);
    expect(find.text('是'), findsOneWidget);
  });

  testWidgets('a successful empty payload still says there are no questions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConstitutionTestV2(loadQuestions: () async => const []),
    ));
    await tester.pumpAndSettle();
    expect(find.text('暂无题目'), findsOneWidget);
  });
}
