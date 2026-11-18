import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/widgets/signup_source_card.dart';

const _labels = ['小红书', '抖音', '视频号', '公众号', '知乎', '哔哩哔哩', '搜索', '朋友推荐', '其他'];
const _codes = [
  'xiaohongshu', 'douyin', 'shipinhao', 'gongzhonghao', 'zhihu',
  'bilibili', 'search', 'friend', 'other',
];

Map<String, dynamic> _enabledBody() => {
      'success': true,
      'data': {
        'enabled': true,
        'question': '从哪知道我们',
        'skippable': true,
        'options': [
          for (var i = 0; i < _codes.length; i++) {'code': _codes[i], 'label': _labels[i]},
        ],
      },
    };

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('flag off or malformed responses hide the question', () {
    expect(parseSignupSourceOptions({'success': true, 'data': {'enabled': false, 'options': []}}), isNull);
    expect(parseSignupSourceOptions(null), isNull);
    expect(parseSignupSourceOptions({'data': {'enabled': true, 'options': []}}), isNull);
    final parsed = parseSignupSourceOptions(_enabledBody())!;
    expect(parsed.map((o) => o.label).toList(), _labels);
    expect(parsed.map((o) => o.code).toList(), _codes);
  });

  testWidgets('renders nothing when the flag is off', (tester) async {
    await tester.pumpWidget(_host(SignupSourceCard(loader: () async => null)));
    await tester.pumpAndSettle();
    expect(find.text('从哪知道我们（选填）'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('renders nothing when the flag lookup fails', (tester) async {
    await tester.pumpWidget(_host(SignupSourceCard(loader: () async => throw Exception('offline'))));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('shows nine options and submits only the chosen code', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(_host(SignupSourceCard(
      loader: () async => parseSignupSourceOptions(_enabledBody()),
      submitter: (code) async => submitted.add(code),
    )));
    await tester.pumpAndSettle();
    expect(find.text('从哪知道我们（选填）'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(9));
    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('哔哩哔哩'));
    await tester.pumpAndSettle();
    expect(submitted, ['bilibili']);
    expect(find.byType(ChoiceChip), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(signupSourceDonePrefKey), isTrue);
  });

  testWidgets('skip hides the question without submitting', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(_host(SignupSourceCard(
      loader: () async => parseSignupSourceOptions(_enabledBody()),
      submitter: (code) async => submitted.add(code),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(submitted, isEmpty);
    expect(find.byType(ChoiceChip), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(signupSourceDonePrefKey), isTrue);
  });

  testWidgets('does not ask again after answering or skipping', (tester) async {
    SharedPreferences.setMockInitialValues({signupSourceDonePrefKey: true});
    var asked = false;
    await tester.pumpWidget(_host(SignupSourceCard(loader: () async {
      asked = true;
      return parseSignupSourceOptions(_enabledBody());
    })));
    await tester.pumpAndSettle();
    expect(asked, isFalse);
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
