import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/tts_player_service.dart';
import 'package:shunshi/data/services/voice_service.dart';
import 'package:shunshi/presentation/pages/chat/voice_chrome.dart';
import 'package:shunshi/presentation/pages/home/widgets/today_voice_bar.dart';

class FakeVoice implements VoiceInput {
  @override
  String errorMsg = '';
  int starts = 0;

  @override
  Future<bool> startRecording() async {
    starts++;
    return true;
  }

  @override
  Future<String?> stopAndRecognize() async => '泡脚';

  @override
  Future<void> cancel() async {}
}

class FakePlayback extends ChangeNotifier implements SpeechPlayback {
  @override
  String? activeKey;
  @override
  bool isSpeaking = false;
  @override
  String errorMsg = '';
  String? lastText;

  @override
  Future<bool> speak(String text, {String key = 'default'}) async {
    lastText = text;
    activeKey = key;
    isSpeaking = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> stop() async {
    isSpeaking = false;
    activeKey = null;
    notifyListeners();
  }
}

void main() {
  testWidgets('today offers a tap speaker and voice input without a live microphone', (tester) async {
    final voice = FakeVoice();
    final playback = FakePlayback();
    final heard = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TodayVoiceBar(
          spokenText: '大寒 **09:45**。大雪 10:53。',
          voiceInput: voice,
          playback: playback,
          chrome: VoiceChrome.browser,
          onTranscript: heard.add,
        ),
      ),
    ));

    expect(find.text('朗读今日'), findsOneWidget);
    expect(find.text('用语音说'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-speaker')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-voice-input')), findsOneWidget);

    await tester.tap(find.text('朗读今日'));
    await tester.pump();
    expect(playback.lastText, '大寒 09:45。大雪 10:53。');
    expect(playback.lastText, isNot(contains('*')));
    expect(playback.activeKey, 'today');

    await tester.tap(find.text('用语音说'));
    await tester.pumpAndSettle();
    expect(voice.starts, 1);
    expect(find.text('停止并转写'), findsOneWidget);
    expect(find.text('正在听。说完后再点一次，文字会留在这里。'), findsOneWidget);

    await tester.tap(find.text('停止并转写'));
    await tester.pumpAndSettle();
    expect(heard, ['泡脚']);
    expect(find.text('泡脚'), findsOneWidget);
  });
}
