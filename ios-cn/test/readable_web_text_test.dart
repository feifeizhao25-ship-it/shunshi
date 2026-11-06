import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/home/ultimate_home_page.dart';
import 'package:shunshi/presentation/pages/home/widgets/today_voice_bar.dart';
import 'package:shunshi/presentation/pages/onboarding/wellness_onboarding_page.dart';
import 'package:shunshi/presentation/pages/chat/voice_chrome.dart';
import 'package:shunshi/presentation/widgets/empty_state.dart';
import 'package:shunshi/web/readable_semantics.dart';

void main() {
  testWidgets('guest welcome copy is in the semantics text, without a microphone', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: WellnessOnboardingPage()));
    await tester.pump();

    final copy = collectReadableSemanticsText();
    expect(copy, contains('顺时'));
    expect(copy, contains('顺应天时，养身心'));
    expect(copy, contains('开始使用'));
    expect(find.text('用语音说'), findsNothing);
    expect(find.byKey(const ValueKey('today-voice-input')), findsNothing);

    handle.dispose();
  });

  testWidgets('season time, speak control, loading, and empty copy are readable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: const [
            SolarTermPill(label: '大寒 · 2026-01-20 09:45', color: Color(0xFF144227)),
            Text('大雪 10:53'),
            TodayVoiceBar(spokenText: '大寒 09:45', chrome: VoiceChrome.browser),
            LoadingExplain(),
            EmptyState(
              icon: Icons.inbox_outlined,
              title: '今天还没有记录',
              description: '先记下一件小事，明天就能在这里看到。',
            ),
          ],
        ),
      ),
    ));

    final copy = collectReadableSemanticsText();
    expect(copy, contains('大寒 · 2026-01-20 09:45'));
    expect(copy, contains('10:53'));
    expect(copy, contains('朗读今日'));
    expect(copy, contains('用语音说'));
    expect(copy, contains('正在加载'));
    expect(copy, contains('今天还没有记录'));
    expect(copy, contains('先记下一件小事'));

    handle.dispose();
  });

  testWidgets('a narrow season chip still exposes the full time in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    const label = '大寒 09:45 · 大雪 10:53 · 把这一行放进很窄的胶囊里也不要丢掉时刻';
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 72, child: SolarTermPill(label: label, color: Color(0xFF144227)))),
      ),
    ));

    expect(collectReadableSemanticsText(), contains('09:45'));
    expect(collectReadableSemanticsText(), contains('10:53'));
    expect(collectReadableSemanticsText(), contains(label));

    handle.dispose();
  });
}
