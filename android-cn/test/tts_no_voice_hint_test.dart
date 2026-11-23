import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shunshi/data/services/tts_player_service.dart';

class _FakeTts extends FlutterTts {
  _FakeTts(this.voices);
  final List<Map<String, String>> voices;
  int speaks = 0;
  @override
  Future<dynamic> get getVoices async => voices;
  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;
  @override
  Future<dynamic> setLanguage(String language) async => 1;
  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setVolume(double volume) async => 1;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speaks++;
    return 1;
  }
  @override
  Future<dynamic> stop() async => 1;
}

Future<void> _settle(TtsPlayerService s) async {
  for (var i = 0; i < 50 && s.isSpeaking; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('网页端没有中文语音：马上提示，不假装在读（问题 50）', () async {
    final tts = _FakeTts([]);
    final s = TtsPlayerService.detached(tts: tts, checkDeviceVoices: true, baseUrl: 'http://127.0.0.1:9');
    await s.speak('今天小雪，早点休息');
    await _settle(s);
    expect(s.isSpeaking, isFalse);
    expect(s.errorMsg, s.noVoiceMessage);
    expect(tts.speaks, 0);
  });

  test('只有英文语音也算没有中文语音', () async {
    final tts = _FakeTts([{'name': 'Samantha', 'locale': 'en-US'}]);
    final s = TtsPlayerService.detached(tts: tts, checkDeviceVoices: true, baseUrl: 'http://127.0.0.1:9');
    await s.speak('今天小雪');
    await _settle(s);
    expect(s.errorMsg, s.noVoiceMessage);
    expect(tts.speaks, 0);
  });

  test('有中文语音时照常朗读', () async {
    final tts = _FakeTts([{'name': 'Tingting', 'locale': 'zh-CN'}]);
    final s = TtsPlayerService.detached(tts: tts, checkDeviceVoices: true, baseUrl: 'http://127.0.0.1:9');
    await s.speak('今天小雪');
    await _settle(s);
    expect(tts.speaks, 1);
    expect(s.errorMsg, isEmpty);
  });
}
