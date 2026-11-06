import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/home/ultimate_home_page.dart';
import 'package:seasons/presentation/pages/home/widgets/today_voice_bar.dart';
import 'package:seasons/presentation/pages/onboarding/onboarding_page.dart';
import 'package:seasons/presentation/pages/chat/voice_chrome.dart';
import 'package:seasons/presentation/widgets/empty_state.dart';
import 'package:seasons/web/readable_semantics.dart';

void main() {
  testWidgets('guest welcome copy is in the semantics text, without a microphone', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pump();

    final copy = collectReadableSemanticsText();
    expect(copy, contains('SEASONS'));
    expect(copy, contains('been feeling'));
    expect(copy, contains('There are no wrong answers.'));
    expect(copy, contains('Calm'));
    expect(copy, contains('Continue'));
    expect(find.text('Speak'), findsNothing);
    expect(find.byKey(const ValueKey('today-voice-input')), findsNothing);

    handle.dispose();
  });

  testWidgets('season time, speak control, loading, and empty copy are readable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: const [
            SolarTermPill(label: 'Major Cold · 2026-01-20 09:45', color: Color(0xFF5B4B8A)),
            Text('Major Snow 10:53'),
            TodayVoiceBar(spokenText: 'Major Cold 09:45', chrome: VoiceChrome.browser),
            LoadingExplain(message: 'Loading. If this stays here, go back and open it again.'),
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here yet',
              description: 'Write one small note and it will show up here.',
            ),
          ],
        ),
      ),
    ));

    final copy = collectReadableSemanticsText();
    expect(copy, contains('Major Cold · 2026-01-20 09:45'));
    expect(copy, contains('10:53'));
    expect(copy, contains('Read today'));
    expect(copy, contains('Speak'));
    expect(copy, contains('Loading. If this stays here'));
    expect(copy, contains('Nothing here yet'));
    expect(copy, contains('Write one small note'));

    handle.dispose();
  });

  testWidgets('a narrow season chip still exposes the full time in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    const label = 'Major Cold 09:45 · Major Snow 10:53 · keep the clock time when the chip is narrow';
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 72, child: SolarTermPill(label: label, color: Color(0xFF5B4B8A)))),
      ),
    ));

    expect(collectReadableSemanticsText(), contains('09:45'));
    expect(collectReadableSemanticsText(), contains('10:53'));
    expect(collectReadableSemanticsText(), contains(label));

    handle.dispose();
  });
}
