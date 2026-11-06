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
    await tester.pumpAndSettle();
    // Splash schedules a one-shot jump even after `/` replaces it.
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('稍作停顿'), findsNothing);
    expect(find.text('页面遇到了一点小问题'), findsNothing);
    expect(find.text('顺应天时，养身心'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.text('顺时'), findsWidgets);
    expect(find.text('用语音说'), findsNothing);
    expect(AppRouter.router.routerDelegate.currentConfiguration.error, isNull);
    expect(AppRouter.router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(tester.takeException(), isNull);
  });
}
