// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shunshi/data/services/voice_service.dart';
import 'package:shunshi/data/services/web_speech.dart';
import 'package:shunshi/presentation/pages/chat/voice_chrome.dart';
import 'package:shunshi/presentation/pages/home/widgets/today_voice_bar.dart';

class _LateDeniedVoice implements VoiceInput, LateVoiceFailure {
  @override
  String errorMsg = '';
  @override
  void Function(String message)? onLateFailure;
  @override
  Future<bool> startRecording() async => true;
  @override
  Future<String?> stopAndRecognize() async => null;
  @override
  Future<void> cancel() async {}
}

/// 浏览器语音识别的替身：可以在 listen 里同步拒绝，或者 listen 之后再异步拒绝。
class _FakeSpeech extends SpeechToText {
  _FakeSpeech({this.denyDuringListen = false}) : super.withMethodChannel();
  final bool denyDuringListen;
  SpeechErrorListener? _onError;

  void denyLater() => _onError?.call(SpeechRecognitionError('not-allowed', true));

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _onError = onError;
    return true;
  }

  @override
  Future listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    if (denyDuringListen) denyLater();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

WebSpeechSession _session(SpeechToText s) => WebSpeechSession(
      localeId: 'zh_CN',
      permissionMessage: '请授予麦克风权限',
      unavailableMessage: '不支持',
      emptyMessage: '未识别到语音内容',
      missedMessage: '没有听清',
      speech: s,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('listen 时就被拒绝：start 返回 false，界面不会进入「正在听」（问题 51）', () async {
    final denied = <String>[];
    final s = _session(_FakeSpeech(denyDuringListen: true))..onDenied = denied.add;
    expect(await s.start(), isFalse);
    expect(s.errorMsg, '请授予麦克风权限');
    expect(denied, ['请授予麦克风权限']);
  });

  test('开始后才被拒绝：马上通知，不用等点「停止」', () async {
    final fake = _FakeSpeech();
    final denied = <String>[];
    final s = _session(fake)..onDenied = denied.add;
    expect(await s.start(), isTrue);
    fake.denyLater();
    expect(denied, ['请授予麦克风权限']);
    expect(s.permissionDenied, isTrue);
  });

  testWidgets('首页语音条：权限被拒后立刻收起「正在听」并提示', (tester) async {
    final voice = _LateDeniedVoice();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TodayVoiceBar(spokenText: '小雪', voiceInput: voice, chrome: VoiceChrome.browser)),
    ));
    await tester.tap(find.byKey(const ValueKey('today-voice-input')));
    await tester.pump();
    expect(find.text(kTodayVoiceListeningHint), findsOneWidget);
    voice.onLateFailure!('请授予麦克风权限');
    await tester.pump();
    expect(find.text(kTodayVoiceListeningHint), findsNothing);
    expect(find.text('请授予麦克风权限'), findsOneWidget);
  });
}
