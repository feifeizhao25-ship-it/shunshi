/*
SEASONS Design System - Complete Colors
*/

import 'package:flutter/material.dart';

class SeasonsColors {
  SeasonsColors._();
  
  // Primary
  static const Color primary = skyBlue;
  static const Color primaryLight = skyBlueLight;
  static const Color primaryDark = skyBlueDark;
  static const Color skyBlue = Color(0xFFA7C7E7);
  static const Color skyBlueLight = Color(0xFFC5DDF0);
  static const Color skyBlueDark = Color(0xFF7BAEDD);
  
  // Secondary
  static const Color secondary = warmSand;
  static const Color secondaryLight = warmSandLight;
  static const Color secondaryDark = warmSandDark;
  static const Color warmSand = Color(0xFFEADBC8);
  static const Color warmSandLight = Color(0xFFF5EBE0);
  static const Color warmSandDark = Color(0xFFD4C4B0);
  
  // Accent
  static const Color accent = softSage;
  static const Color softSage = Color(0xFFC3D9C5);
  static const Color softSageLight = Color(0xFFD9EBD8);
  static const Color softSageDark = Color(0xFFA3C1A7);
  static const Color sunsetOrange = Color(0xFFF3A76F);
  static const Color sunsetPink = Color(0xFFE8B4B8);
  
  // Semantic
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFECC94B);
  static const Color info = Color(0xFF4299E1);
  
  // Seasons
  static const Color spring = Color(0xFFA7C7E7);
  static const Color summer = Color(0xFFF3A76F);
  static const Color autumn = Color(0xFFEADBC8);
  static const Color winter = Color(0xFFC5DDF0);
  
  // Light Theme
  static const Color background = Color(0xFFFAFBFC);
  static const Color backgroundLight = Color(0xFFFAFBFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textPrimaryLight = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textTertiaryLight = Color(0xFFA0AEC0);
  
  // Dark Theme
  static const Color deepNight = Color(0xFF1E2A38);
  static const Color darkSurface = Color(0xFF2A3A4A);
  static const Color darkCard = Color(0xFF344350);
  static const Color textPrimaryDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E0);
  static const Color textTertiaryDark = Color(0xFFA0AEC0);
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // Mood colors
  static const Color moodCalm = Color(0xFFA7C7E7);
  static const Color moodHappy = Color(0xFFF3A76F);
  static const Color moodEnergetic = Color(0xFFC3D9C5);
  static const Color moodTired = Color(0xFFCBD5E0);
  static const Color moodAnxious = Color(0xFFE8B4B8);
  static const Color moodSad = Color(0xFF7BAEDD);
  static const Color moodGrateful = Color(0xFF48BB78);
  static const Color moodHopeful = Color(0xFFECC94B);
  
  // Border
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF4A5568);
  
  // Dividers
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF4A5568);
}

class SeasonsSpacing {
  SeasonsSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class SeasonsRadius {
  SeasonsRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}


class SeasonsShadows {
  SeasonsShadows._();
  static List<BoxShadow> get small => [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))];
  static List<BoxShadow> get medium => [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))];
  static List<BoxShadow> get large => [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8))];
  static List<BoxShadow> get smallShadow => small;
}

// Mood colors
class SeasonsMoodColors {
  SeasonsMoodColors._();
  static const Color calm = Color(0xFFA7C7E7);
  static const Color happy = Color(0xFFF3A76F);
  static const Color energetic = Color(0xFFC3D9C5);
  static const Color tired = Color(0xFFCBD5E0);
  static const Color anxious = Color(0xFFE8B4B8);
  static const Color sad = Color(0xFF7BAEDD);
  static const Color grateful = Color(0xFF48BB78);
  static const Color hopeful = Color(0xFFECC94B);
}
