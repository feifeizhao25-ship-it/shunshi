import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/family/family_page_v2.dart';
import 'family_page_test.dart' show FamilyAdapter, api;

const output = String.fromEnvironment('FAMILY_CAPTURE_DIR');
const fontPath = String.fromEnvironment('FAMILY_CAPTURE_FONT');
void main() {
  for (final scenario in ['members', 'offline', 'add']) {
    testWidgets('render $scenario at mobile size', (tester) async {
      await tester.runAsync(() async {
        await (FontLoader('CaptureChinese')..addFont(
              File(fontPath).readAsBytes().then((b) => ByteData.sublistView(b)),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final adapter = FamilyAdapter()..offline = scenario == 'offline';
      adapter.members.add({
        'id': 'two',
        'name': '宝宝',
        'relation': 'child',
        'age': 0,
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'CaptureChinese',
              colorSchemeSeed: const Color(0xFF205C44),
            ),
            home: FamilyPageV2(api: api(adapter)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario == 'add') {
        await tester.tap(find.text('添加家庭成员'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage();
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/$scenario.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        rendered.dispose();
      });
    }, skip: output.isEmpty || fontPath.isEmpty);
  }
}
