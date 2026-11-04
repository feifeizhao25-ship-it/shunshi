import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seasons/presentation/widgets/responsive_frame.dart';
import 'package:seasons/presentation/widgets/shell/main_shell.dart';

/// N-02: the iOS run showed "Duplicate GlobalKey / _CustomNavigator" after the ResponsiveFrame / MainShell change.
/// This replays the app's wiring (root + shell navigator keys, framed vs unframed routes, desktop <-> phone resize,
/// jumping between shell and non-shell routes) and requires that no framework assertion is raised.
void main() {
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();
  late GoRouter router;

  Widget app() {
    router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login'))),
        GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('settings'))),
        ShellRoute(
          navigatorKey: shellKey,
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            for (final p in ['/chat', '/today', '/solar', '/wellness', '/profile'])
              GoRoute(path: p, pageBuilder: (_, __) => NoTransitionPage(child: Scaffold(body: Text('page $p')))),
          ],
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => ResponsiveFrame(
        routeListenable: router.routerDelegate,
        currentPath: () => router.routerDelegate.currentConfiguration.uri.path,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> go(WidgetTester t, String path) async {
    router.go(path);
    await t.pumpAndSettle();
  }

  for (final size in [const Size(1440, 900), const Size(768, 1024), const Size(390, 844)]) {
    testWidgets('no duplicate GlobalKey when moving between shell and non-shell routes at ${size.width.toInt()}px', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      for (final p in ['/today', '/login', '/chat', '/settings', '/profile', '/today', '/solar', '/login']) {
        await go(t, p);
        expect(t.takeException(), isNull, reason: 'after go($p)');
      }
    });
  }

  testWidgets('no duplicate GlobalKey when the window crosses the 900px desktop breakpoint on a shell route', (t) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    t.view.physicalSize = const Size(1440, 900);
    await t.pumpWidget(app());
    await go(t, '/today');
    for (final w in [800.0, 1200.0, 500.0, 1000.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'resize to $w');
    }
    await go(t, '/login');
    t.view.physicalSize = const Size(1440, 900);
    await t.pumpAndSettle();
    await go(t, '/chat');
    expect(t.takeException(), isNull);
  });
}
