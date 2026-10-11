import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/presentation/pages/subscription/subscription_page_v2.dart';

// Optional local rendered-widget evidence. Fixtures are not live purchases.
const output = String.fromEnvironment('MEMBERSHIP_CAPTURE_DIR');
const fontPath = String.fromEnvironment('MEMBERSHIP_CAPTURE_FONT');
void main() {
  for (final scenario in ['paid', 'free', 'offline']) {
    testWidgets('capture $scenario at mobile size', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('CaptureChinese')
          ..addFont(
            File(
              fontPath,
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await font.load();
        await (FontLoader('NotoSerifSC')..addFont(rootBundle.load('assets/fonts/NotoSerifCJKsc-Regular.otf'))).load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'CaptureChinese',
              colorSchemeSeed: const Color(0xFF205C44),
            ),
            home: SubscriptionPageV2(
              loadStatus: () async {
                if (scenario == 'offline') throw StateError('offline fixture');
                return UserSubscriptionStatus(
                  planId: scenario == 'paid' ? 'jiahe' : 'free',
                  planName: scenario == 'paid' ? '家和版' : '免费版',
                  isActive: scenario == 'paid',
                  expiresAt: scenario == 'paid'
                      ? DateTime.utc(2027, 1, 1)
                      : null,
                  features: {},
                );
              },
              loadPlans: () async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: output.isEmpty || fontPath.isEmpty);
  }
}
