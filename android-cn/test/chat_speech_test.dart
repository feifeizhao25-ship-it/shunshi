import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/core/solar_term/solar_term_table.dart';
import 'package:shunshi/data/services/speech_text.dart';
import 'package:shunshi/data/services/tts_player_service.dart';
import 'package:shunshi/data/services/voice_service.dart';
import 'package:shunshi/presentation/pages/chat/voice_chrome.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone speaker plays the reply and the next tap stops', (tester) async {
    final playback = FakePlayback();
    await open(tester, FakeVoice(), playback);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byTooltip('朗读回复'), findsWidgets);
    await tester.tap(find.byTooltip('朗读回复').first);
    await tester.pump();
    expect(playback.speaks, 1);
    final opening = chatOpeningFor(currentSolarTermName() ?? chatOpeningTermFallback);
    expect(playback.lastText, speakableReply(opening.text, [opening.cardTitle, opening.cardSubtitle]));
    expect(find.byIcon(Icons.stop_circle), findsWidgets);
    await tester.tap(find.byTooltip('停止朗读').first);
    await tester.pump();
    expect(playback.stops, greaterThanOrEqualTo(1));
    expect(playback.isSpeaking, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('web compose is a labeled writing desk, not the phone mic row', (tester) async {
    final voice = FakeVoice();
    final playback = FakePlayback();
    await open(tester, voice, playback, chrome: VoiceChrome.browser);
    expect(find.text('用语音说'), findsOneWidget);
    expect(find.text('朗读这段'), findsWidgets);
    expect(find.byIcon(Icons.mic), findsNothing);
    await tester.tap(find.text('朗读这段').first);
    await tester.pump();
    expect(find.text('停止'), findsWidgets);
    await tester.tap(find.text('用语音说'));
    await tester.pumpAndSettle();
    expect(voice.starts, 1);
    expect(find.text('停止并转写'), findsOneWidget);
    expect(find.text('正在听。说完后再点一次，文字会留在上面的格子里。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
