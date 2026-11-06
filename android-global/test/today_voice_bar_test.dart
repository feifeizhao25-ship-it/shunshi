import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/services/tts_player_service.dart';
import 'package:seasons/data/services/voice_service.dart';
import 'package:seasons/presentation/pages/chat/voice_chrome.dart';
import 'package:seasons/presentation/pages/home/widgets/today_voice_bar.dart';

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
  Future<String?> stopAndRecognize() async => 'a short walk';

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
          spokenText: 'Major Cold **09:45**. Major Snow 10:53.',
          voiceInput: voice,
          playback: playback,
          chrome: VoiceChrome.browser,
          onTranscript: heard.add,
        ),
      ),
    ));

    expect(find.text('Read today'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);

    await tester.tap(find.text('Read today'));
    await tester.pump();
    expect(playback.lastText, 'Major Cold 09:45. Major Snow 10:53.');
    expect(playback.lastText, isNot(contains('*')));

    await tester.tap(find.text('Speak'));
    await tester.pumpAndSettle();
    expect(voice.starts, 1);
    expect(find.text('Stop and transcribe'), findsOneWidget);

    await tester.tap(find.text('Stop and transcribe'));
    await tester.pumpAndSettle();
    expect(heard, ['a short walk']);
    expect(find.text('a short walk'), findsOneWidget);
  });
}
