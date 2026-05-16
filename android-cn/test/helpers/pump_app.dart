// test/helpers/pump_app.dart
// 共享 test helper — 包装 MaterialApp + 主题

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/theme/theme.dart';

/// 包装 widget 到 MaterialApp 中用于 widget 测试
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  ThemeData? theme,
  bool darkMode = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? (darkMode ? _darkTheme : _lightTheme),
      home: child,
    ),
  );
}

final _lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF4A7C59),
  scaffoldBackgroundColor: const Color(0xFFFAFAF5),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4A7C59),
    surface: Color(0xFFFAFAF5),
  ),
);

final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6AAF7B),
  scaffoldBackgroundColor: const Color(0xFF1A1A2E),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6AAF7B),
    surface: Color(0xFF1A1A2E),
  ),
);
