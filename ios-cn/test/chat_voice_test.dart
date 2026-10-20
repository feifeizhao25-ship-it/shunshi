import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/services/voice_service.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';

class FakeVoice implements VoiceInput {
  bool allowed = true;
  String? result;
  @override
  String errorMsg = '';
  int starts = 0;
  int cancels = 0;
  Completer<String?>? recognition;
  Completer<bool>? starting;
  @override
  Future<bool> startRecording() async {
    starts++;
    return starting == null ? allowed : await starting!.future;
  }

  @override
  Future<String?> stopAndRecognize() async =>
      recognition == null ? result : await recognition!.future;
  @override
  Future<void> cancel() async {
    cancels++;
  }
}

Future<void> open(WidgetTester tester, FakeVoice voice) async {
  SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
  await tester.pumpWidget(MaterialApp(home: ChatPage(voiceInput: voice)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('permission denial is visible and keeps typed draft', (
    tester,
  ) async {
    final voice = FakeVoice()
      ..allowed = false
      ..errorMsg = '请授予麦克风权限';
    await open(tester, voice);
    await tester.enterText(find.byType(TextField), '保留草稿');
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    expect(find.text('请授予麦克风权限'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '保留草稿',
    );
    expect(find.byIcon(Icons.stop), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'null recognition displays service error instead of silently returning',
    (tester) async {
      final voice = FakeVoice()..errorMsg = '识别服务异常';
      await open(tester, voice);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(find.text('识别服务异常'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'complete recognized text is inserted without automatic sending',
    (tester) async {
      final voice = FakeVoice()..result = '第一段语音\n第二段完整文字';
      await open(tester, voice);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        voice.result,
      );
      expect(
        (await SharedPreferences.getInstance()).getInt('chat_count'),
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('pending recognition preserves newer typed content', (
    tester,
  ) async {
    final voice = FakeVoice()..recognition = Completer<String?>();
    await open(tester, voice);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '刚输入的文字');
    voice.recognition!.complete('识别文字');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '刚输入的文字\n识别文字',
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'rapid start is single flight and leaving cancels late recording',
    (tester) async {
      final voice = FakeVoice()..starting = Completer<bool>();
      await open(tester, voice);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      expect(voice.starts, 1);
      await tester.pumpWidget(const SizedBox());
      voice.starting!.complete(true);
      await tester.pumpAndSettle();
      expect(voice.cancels, greaterThanOrEqualTo(1));
      expect(tester.takeException(), isNull);
    },
  );
}
