import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/data/services/tts_player_service.dart';
import 'package:shunshi/data/services/voice_service.dart';
import 'package:shunshi/design_system/theme.dart';
import 'package:shunshi/presentation/pages/chat_page.dart';
import 'package:shunshi/presentation/pages/subscription/subscription_page_v2.dart';

class _Voice implements VoiceInput {
  @override
  String errorMsg = '';
  @override
  Future<bool> startRecording() async => true;
  @override
  Future<String?> stopAndRecognize() async => null;
  @override
  Future<void> cancel() async {}
}

class _Playback extends ChangeNotifier implements SpeechPlayback {
  @override
  String? activeKey;
  @override
  bool isSpeaking = false;
  @override
  String errorMsg = '';
  @override
  Future<bool> speak(String text, {String key = 'default'}) async => true;
  @override
  Future<void> stop() async {}
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color _colorOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style!.color!;

final _dark = ThemeData(brightness: Brightness.dark);

void main() {
  testWidgets('深色模式聊天页标题对比度 ≥ 4.5（问题 19）', (tester) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'local-test'});
    await tester.pumpWidget(MaterialApp(theme: _dark, home: ChatPage(voiceInput: _Voice(), playback: _Playback())));
    await tester.pumpAndSettle();
    final c = _contrast(_colorOf(tester, '顺时 AI 助手'), ShunShiColors.darkBackground);
    expect(c, greaterThanOrEqualTo(4.5), reason: 'contrast=$c');
  });

  testWidgets('深色模式会员页顶部对比度 ≥ 4.5（问题 19）', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: _dark,
      home: SubscriptionPageV2(
        loadStatus: () async => UserSubscriptionStatus(planId: 'free', planName: '免费版', isActive: false, features: {}),
        loadPlans: () async => [
          SubscriptionPlan(id: 'yiyang_monthly', tier: 'yiyang', name: '颐养版月付', priceCents: 5888, periodName: '30天', description: '测试套餐', features: {}, isRecommended: true),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    for (final t in ['会员中心', '选择您的会员方案']) {
      final c = _contrast(_colorOf(tester, t), ShunShiColors.darkBackground);
      expect(c, greaterThanOrEqualTo(4.5), reason: '$t contrast=$c');
    }
  });
}
