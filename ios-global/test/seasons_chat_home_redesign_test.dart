import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/chat/chat_topic_cards.dart';
import 'package:seasons/presentation/widgets/personal_home_section.dart';
import 'package:seasons/presentation/widgets/personal_home_strings_en.dart';

final _cjk = RegExp(r'[\u3400-\u9fff]');

void main() {
  testWidgets('chat topic cards show photos and send the topic prompt when tapped', (tester) async {
    String? picked;
    await tester.binding.setSurfaceSize(const Size(390, 700));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChatTopicCards(onPick: (t) => picked = t))));
    expect(find.text('Sleep better'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('chat_topic_0')));
    expect(picked, kChatTopics.first.prompt);
    for (final t in kChatTopics) {
      expect(_cjk.hasMatch('${t.label}${t.prompt}'), isFalse, reason: 'English edition only');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home suggestion cards use a wellness photo for known categories and an icon otherwise', (tester) async {
    final json = {
      'greeting': 'Good morning',
      'hero': {'id': 'c0', 'title': 'x'},
      'personalization': {'enabled': true},
      'suggestions': [
        {'id': 'a', 'category': 'sleep', 'title': 'Dim the lights', 'description': 'Dim the lights', 'reason': 'Because it is evening'},
        {'id': 'b', 'category': 'unknown_kind', 'title': 'Something else', 'description': 'Something else', 'reason': 'Because'},
      ],
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PersonalHomeSection(
            strings: kPersonalHomeStringsEn,
            api: PersonalHomeApi(load: () async => json, setEnabled: (_) async {}),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-photo-a')), findsOneWidget);
    expect(find.byKey(const Key('personal-home-photo-b')), findsNothing);
    expect(find.byKey(const Key('personal-home-card-b')), findsOneWidget);
  });
}
