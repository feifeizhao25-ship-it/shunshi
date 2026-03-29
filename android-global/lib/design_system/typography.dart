/*
SEASONS Design System - Typography
Clean, soft, readable
*/

import 'package:flutter/material.dart';

class SeasonsTypography {
  SeasonsTypography._();

  // Material Typography Scale
  static const TextStyle displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.w400);
  static const TextStyle displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w400);
  static const TextStyle displaySmall = TextStyle(fontSize: 36, fontWeight: FontWeight.w400);
  static const TextStyle headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w400);
  static const TextStyle headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w400);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.w400);
  static const TextStyle titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);

  // Light theme styles
  static const TextStyle h1Light = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF2D3748), letterSpacing: -0.5);
  static const TextStyle h2Light = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF2D3748));
  static const TextStyle h3Light = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D3748));
  static const TextStyle h4Light = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748));
  static const TextStyle bodyLight = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF4A5568), height: 1.5);
  static const TextStyle bodySmallLight = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF718096), height: 1.4);
  static const TextStyle captionLight = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFA0AEC0));
  static const TextStyle labelLight = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF718096));
  static const TextStyle buttonLight = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF), letterSpacing: 0.3);
  static const TextStyle quoteLight = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF4A5568), fontStyle: FontStyle.italic, height: 1.6);

  // Dark theme styles
  static const TextStyle h1Dark = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFF7FAFC), letterSpacing: -0.5);
  static const TextStyle h2Dark = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF7FAFC));
  static const TextStyle h3Dark = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF7FAFC));
  static const TextStyle h4Dark = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF7FAFC));
  static const TextStyle bodyDark = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFCBD5E0), height: 1.5);
  static const TextStyle bodySmallDark = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFA0AEC0), height: 1.4);
  static const TextStyle captionDark = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF718096));
  static const TextStyle labelDark = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFA0AEC0));
  static const TextStyle buttonDark = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D3748), letterSpacing: 0.3);
  static const TextStyle quoteDark = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFCBD5E0), fontStyle: FontStyle.italic, height: 1.6);
}

class SeasonsTextTheme {
  SeasonsTextTheme._();

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Color(0xFF2D3748)),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF4A5568)),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF4A5568)),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF4A5568)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2D3748)),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Color(0xFFF7FAFC)),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFCBD5E0)),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFCBD5E0)),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFCBD5E0)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFF7FAFC)),
  );
}
