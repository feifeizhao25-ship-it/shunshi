import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/solar_term.dart';

extension SolarTermColor on SolarTerm {
  Color get themeColor {
    if (colorHex != null && colorHex!.isNotEmpty) {
      final hexCode = colorHex!.replaceAll('#', '');
      if (hexCode.length == 6 || hexCode.length == 8) {
        return Color(int.parse('FF$hexCode', radix: 16));
      }
    }
    
    switch (season) {
      case Season.spring: return AppColors.spring;
      case Season.summer: return AppColors.summer;
      case Season.autumn: return AppColors.autumn;
      case Season.winter: return AppColors.winter;
    }
  }
}
