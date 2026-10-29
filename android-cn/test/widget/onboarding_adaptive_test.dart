import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/design_system/theme.dart';
import 'package:shunshi/presentation/pages/onboarding/wellness_onboarding_page.dart';
import 'package:shunshi/presentation/widgets/responsive_frame.dart';

const _beige = Color(0xFFE7E0D4);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unset theme follows the system', () {
    expect(ThemeNotifier().mode, ThemeMode.system);
  });

  testWidgets('phone welcome stays full width in light and dark', (tester) async {
    await _pump(tester, const Size(402, 874), ThemeMode.light);
    _expectPhone(tester, 402);
    expect(_titleColor(tester), ShunShiColors.textPrimary);
    expect(_scaffoldColor(tester), ShunShiColors.background);
    await _save(tester, 'android-iphone-width-onboarding-light');

    await _pump(tester, const Size(360, 800), ThemeMode.dark);
    _expectPhone(tester, 360);
    expect(_titleColor(tester), ShunShiColors.darkTextPrimary);
    expect(_scaffoldColor(tester), ShunShiColors.darkBackground);
    expect(_buttonForeground(tester), const Color(0xFF121212));
    await _save(tester, 'android-galaxy-s24-onboarding-dark');
  });

  testWidgets('iPad Pro 13 welcome uses a wide column and a dark theme', (tester) async {
    await _pump(tester, const Size(1032, 1376), ThemeMode.light);
    _expectTablet(tester);
    expect(_titleColor(tester), ShunShiColors.textPrimary);
    final title = tester.widget<Text>(find.text('顺时'));
    expect(title.style?.fontSize, 52);
    await _save(tester, 'android-ipad-pro-13-onboarding-light');

    await _pump(tester, const Size(1032, 1376), ThemeMode.dark);
    _expectTablet(tester);
    expect(_titleColor(tester), ShunShiColors.darkTextPrimary);
    expect(_scaffoldColor(tester), ShunShiColors.darkBackground);
    expect(_buttonForeground(tester), const Color(0xFF121212));
    await _save(tester, 'android-ipad-pro-13-onboarding-dark');
  });
}

var _fontsLoaded = false;

Future<void> _ensureFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    Future<void> load(String family, List<String> assets) async {
      final loader = FontLoader(family);
      for (final asset in assets) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
    await load('NotoSerifSC', const [
      'assets/fonts/NotoSerifSC-Regular.ttf',
      'assets/fonts/NotoSerifSC-Bold.ttf',
    ]);
    await load('NotoSansSC', const [
      'assets/fonts/NotoSansSC-Regular.ttf',
      'assets/fonts/NotoSansSC-Bold.ttf',
    ]);
    final icons = File('/home/ubuntu/sdks/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  });
  _fontsLoaded = true;
}

Future<void> _pump(WidgetTester tester, Size logical, ThemeMode mode) async {
  await _ensureFonts(tester);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
    await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('app-${mode.name}-${logical.width}x${logical.height}'),
      theme: ShunShiTheme.lightTheme,
      darkTheme: ShunShiTheme.darkTheme,
      themeMode: mode,
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('adaptive-shot'),
        child: ResponsiveFrame(child: child ?? const SizedBox.shrink()),
      ),
      home: const WellnessOnboardingPage(),
    ),
  );
  await tester.pump();
}

void _expectPhone(WidgetTester tester, double width) {
  final media = MediaQuery.of(tester.element(find.byType(WellnessOnboardingPage)));
  expect(media.size.width, width);
  expect(media.textScaler.scale(1), 1);
  expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == _beige), findsNothing);
  final button = tester.getSize(find.widgetWithText(ElevatedButton, '开始使用'));
  expect(button.width, inInclusiveRange(300, 420));
  expect(tester.takeException(), isNull);
}

void _expectTablet(WidgetTester tester) {
  final media = MediaQuery.of(tester.element(find.byType(WellnessOnboardingPage)));
  expect(media.size.width, 760);
  expect(media.textScaler.scale(1), closeTo(1.16, 0.01));
  expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == _beige), findsNothing);
  final button = tester.getSize(find.widgetWithText(ElevatedButton, '开始使用'));
  expect(button.width, greaterThan(600));
  expect(tester.takeException(), isNull);
}

Color? _titleColor(WidgetTester tester) => tester.widget<Text>(find.text('顺时')).style?.color;

Color? _scaffoldColor(WidgetTester tester) => tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;

Color? _buttonForeground(WidgetTester tester) {
  final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '开始使用'));
  return button.style?.foregroundColor?.resolve(const <WidgetState>{});
}

Future<void> _save(WidgetTester tester, String name) async {
  final dir = Directory('/tmp/shunshi-shots/after');
  dir.createSync(recursive: true);
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('adaptive-shot')));
  final image = boundary.toImageSync();
  await tester.runAsync(() async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await File('${dir.path}/$name.png').writeAsBytes(data.buffer.asUint8List(), flush: true);
  });
}
