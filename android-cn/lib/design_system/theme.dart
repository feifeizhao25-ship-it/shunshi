// Design System - 顺时 Flutter 专用
// 基于提示词要求：东方自然、温和、米白背景、青绿主色

import 'package:flutter/material.dart';

class ShunShiColors {
  // 主色 - 青绿系
  static const Color primary = Color(0xFF4A7C6F);
  static const Color primaryLight = Color(0xFF6B9E8F);
  static const Color primaryDark = Color(0xFF2D5A4D);
  
  // 背景色 - 米白系
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F2ED);
  
  // 点缀色
  static const Color accent = Color(0xFFE8A87C);
  static const Color accentLight = Color(0xFFF5D6C1);
  static const Color gold = Color(0xFFD4B896);
  static const Color blue = Color(0xFF8EB8C9);
  
  // 中性色
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);
  static const Color textDisabled = Color(0xFFCCCCCC);
  
  // 边框与分割
  static const Color border = Color(0xFFE8E5E0);
  static const Color divider = Color(0xFFF0EDEA);
  
  // 状态色（柔和）
  static const Color success = Color(0xFF6B9E8F);
  static const Color warning = Color(0xFFE8A87C);
  static const Color error = Color(0xFFD4726A);
  static const Color info = Color(0xFF8EB8C9);
}

class ShunShiTypography {
  static const String fontFamily = 'Noto Sans SC';
  
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.3,
  );
 static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textTertiary,
    height: 1.4,
  );
}

class ShunShiSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  
  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double listItemPadding = 12;
}

class ShunShiRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(999));
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

class ShunShiShadows {
  static const List<BoxShadow> none = [];
  
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x0C000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}

class ShunShiTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: ShunShiColors.primary,
        onPrimary: Colors.white,
        primaryContainer: ShunShiColors.primaryLight,
        secondary: ShunShiColors.accent,
        onSecondary: Colors.white,
        surface: ShunShiColors.surface,
        onSurface: ShunShiColors.textPrimary,
        error: ShunShiColors.error,
      ),
      scaffoldBackgroundColor: ShunShiColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: ShunShiColors.surface,
        foregroundColor: ShunShiColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: ShunShiTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: ShunShiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.cardRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunShiColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: ShunShiRadius.buttonRadius,
          ),
          textStyle: ShunShiTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShunShiColors.primary,
          side: BorderSide(color: ShunShiColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: ShunShiRadius.buttonRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShunShiColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShunShiColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(ShunShiRadius.md)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(ShunShiRadius.md)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(ShunShiRadius.md)),
          borderSide: BorderSide(color: ShunShiColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ShunShiColors.surfaceVariant,
        selectedColor: ShunShiColors.primaryLight,
        labelStyle: ShunShiTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.chipRadius,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ShunShiColors.surface,
        indicatorColor: ShunShiColors.primaryLight.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ShunShiTypography.labelMedium.copyWith(color: ShunShiColors.primary);
          }
          return ShunShiTypography.labelMedium;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: ShunShiColors.divider,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ShunShiColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.bottomSheetRadius,
        ),
      ),
    );
  }
}

// 老年模式主题（放大）
class ShunShiElderlyTheme {
  static ThemeData get theme {
    final base = ShunShiTheme.lightTheme;
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontSizeFactor: 1.3,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: ShunShiTypography.headlineMedium,
      ),
    );
  }
}
