import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/services/tts_player_service.dart';
import 'package:seasons/data/services/voice_service.dart';
import 'package:seasons/presentation/pages/chat/voice_chrome.dart';
import 'package:seasons/presentation/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int speaks = 0;
  int stops = 0;

  @override
  Future<bool> speak(String text, {String key = 'default'}) async {
    speaks++;
    lastText = text;
    activeKey = key;
    isSpeaking = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> stop() async {
    stops++;
    isSpeaking = false;
    activeKey = null;
    notifyListeners();
  }
}

Future<void> open(WidgetTester tester, FakeVoice voice, FakePlayback playback, {VoiceChrome? chrome}) async {
  SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
  await tester.pumpWidget(MaterialApp(home: ChatPage(voiceInput: voice, playback: playback, chrome: chrome)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('phone speaker plays the reply and the next tap stops', (tester) async {
    final playback = FakePlayback();
    await open(tester, FakeVoice(), playback);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    final read = find.byTooltip('Read aloud');
    expect(read, findsWidgets);
    await tester.ensureVisible(read.first);
    await tester.tap(read.first);
    await tester.pump();
    expect(playback.speaks, 1);
    expect(playback.lastText, isNotEmpty);
    expect(find.byIcon(Icons.stop_circle), findsWidgets);
    await tester.tap(find.byTooltip('Stop reading').first);
    await tester.pump();
    expect(playback.isSpeaking, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('web compose is a labeled writing desk, not the phone mic row', (tester) async {
    final voice = FakeVoice();
    final playback = FakePlayback();
    await open(tester, voice, playback, chrome: VoiceChrome.browser);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Read this'), findsWidgets);
    expect(find.byIcon(Icons.mic), findsNothing);
    await tester.tap(find.text('Read this').first);
    await tester.pump();
    expect(find.text('Stop'), findsWidgets);
    await tester.tap(find.text('Speak'));
    await tester.pump();
    expect(voice.starts, 1);
    expect(find.text('Stop and transcribe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
