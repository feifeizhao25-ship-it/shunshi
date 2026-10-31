// Finishing onboarding must land on the home route (it used to call Navigator.pushReplacementNamed,
// which a go_router app does not handle, so the last step did nothing).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/presentation/pages/onboarding/onboarding_page.dart';

void main() {
  testWidgets('last onboarding step navigates to /home and marks onboarding done', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
      GoRoute(path: '/home', builder: (c, s) => const Scaffold(body: Text('HOME-ROUTE'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 500));
    for (final choice in ['Calm', 'Sleep', 'Student', 'Morning', 'Minimal']) {
      await tester.tap(find.text(choice));
      await tester.pump();
      final next = find.text(choice == 'Minimal' ? 'Begin My Journey' : 'Continue');
      await tester.tap(next);
      if (choice != 'Minimal') await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pumpAndSettle();
    expect(find.text('HOME-ROUTE'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('onboarding_completed'), isTrue);
  });
}
