import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/responsive_frame.dart';
import 'package:seasons/presentation/widgets/shell/desktop_shell.dart';

void main() {
  const items = [
    DesktopNavItem(path: '/a', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Alpha'),
    DesktopNavItem(path: '/b', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Beta'),
  ];
  Widget shell(String sel, ValueChanged<String> on) => DesktopShell(
        items: items,
        currentPath: sel,
        onSelect: on,
        background: Colors.white,
        line: Colors.grey,
        active: Colors.teal,
        inactive: Colors.black54,
        title: 'App',
        child: const SizedBox.expand(key: Key('content')),
      );

  testWidgets('wide: sidebar with every tab, content capped at 960px', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? tapped;
    await tester.pumpWidget(MaterialApp(home: shell('/a', (p) => tapped = p)));
    expect(DesktopShell.isWide(tester.element(find.byType(DesktopShell))), isTrue);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('content'))).width, 960);
    await tester.tap(find.text('Beta'));
    expect(tapped, '/b');
  });

  testWidgets('narrow window is not treated as desktop', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: shell('/a', (_) {})));
    expect(DesktopShell.isWide(tester.element(find.byType(DesktopShell))), isFalse);
  });

  testWidgets('ResponsiveFrame lets the main-tab routes use the full 1440 window, other routes stay framed', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<double> widthAt(String path) async {
      await tester.pumpWidget(MaterialApp(home: ResponsiveFrame(currentPath: () => path, child: const SizedBox.expand(key: Key('page')))));
      return tester.getSize(find.byKey(const Key('page'))).width;
    }

    expect(await widthAt('/today'), 1440);
    expect(await widthAt('/login'), lessThanOrEqualTo(880));
  });
}
