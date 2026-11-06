import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/core/router/app_router.dart';
import 'package:shunshi/data/storage/storage_manager.dart';
import 'package:shunshi/main.dart';

/// Boots the real AppRouter at `/`. An isolated onboarding widget pump can
/// pass while this route still throws `GoException: no routes for location: /`.
void main() {
  testWidgets('guest / shows the welcome and not the calm error card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    await tester.pumpWidget(const ShunshiApp());
    await tester.pump();

    final handled = await tester.binding.handlePushRoute('/');
    expect(handled, isTrue);
    // The welcome page breathes forever, so pumpAndSettle never goes idle.
    // Stop before splash's 2.2s timer, or that timer leaves `/` for onboarding.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('开始使用').evaluate().isNotEmpty) break;
    }

    expect(find.text('稍作停顿'), findsNothing);
    expect(find.text('页面遇到了一点小问题'), findsNothing);
    expect(find.text('顺应天时，养身心'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.text('顺时'), findsWidgets);
    expect(find.text('用语音说'), findsNothing);
    expect(AppRouter.router.routerDelegate.currentConfiguration.error, isNull);
    expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(tester.takeException(), isNull);

    // Advance in small steps so splash's exit finishes and disposes its
    // one-shot timer before that timer can navigate away from `/`.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('稍作停顿'), findsNothing);
    expect(find.text('开始使用'), findsOneWidget);
    expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(tester.takeException(), isNull);
  });
}
