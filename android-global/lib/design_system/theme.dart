// Design System - 顺时 Flutter 专用
// 基于 Notion 风格设计系统：温暖中性色调、柔和圆角、纸质触感

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShunShiColors {
  // ── 主色：墨绿（"The Digital Scroll" 设计规范）──
  static const Color primary = Color(0xFF144227);
  static const Color primaryContainer = Color(0xFF2D5A3D);
  static const Color primaryLight = Color(0xFF3E7A55);
  static const Color primaryDark = primaryContainer;
  
  // ── 辅助色：暖杏 ──
  static const Color secondary = Color(0xFF74593C);
  static const Color secondaryLight = Color(0xFF9E9080);
  
  // ── 背景：宣纸白（#fdf9f4）──
  static const Color background = Color(0xFFFDF9F4);
  static const Color surface = Color(0xFFFDF9F4);
  static const Color surfaceContainerLow = Color(0xFFF7F3EE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = surfaceContainerLow;
  
  // ── 点缀色 ──
  static const Color gold = Color(0xFF4C3605);
  static const Color goldLight = Color(0xFFE4C285);
  static const Color apricot = Color(0xFFD4956B);
  static const Color apricotLight = Color(0xFFF0D4BF);
  static const Color accent = apricot;
  static const Color accentLight = apricotLight;
  static const Color blue = Color(0xFF6B8FAD);
  static const Color calm = Color(0xFF9BB8C9);
  static const Color warm = Color(0xFFD4A574);
  
  // ── 文字色：不用纯黑，用 onBackground #1C1C19 ──
  static const Color textPrimary = Color(0xFF1C1C19);
  static const Color textSecondary = Color(0xFF6B7B7D);
  static const Color textTertiary = Color(0xFF9CA3A5);
  static const Color textDisabled = Color(0xFFB5BBBD);
  
  // ── 边框（Ghost Border: 20% opacity，无硬线原则）──
  static const Color borderGhost = Color(0x331C1C19);
  static const Color border = Color(0x331C1C19);
  static const Color divider = Color(0x1A1C1C19);
  
  // ── 状态色（温低饱和）──
  static const Color success = Color(0xFF144227);
  static const Color warning = Color(0xFFE8C87A);
  static const Color error = Color(0xFFB85450);
  static const Color info = Color(0xFF6B8FAD);

  // ── 深色主题（禅意深色）──
  static const Color darkPrimary = Color(0xFFA8B89E);
  static const Color darkSecondary = Color(0xFFC4AD8C);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceContainerLow = Color(0xFF1A1A1A);
  static const Color darkSurfaceContainerLowest = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFE8E6E1);
  static const Color darkTextSecondary = Color(0xFF9C9C96);
  static const Color darkTextTertiary = Color(0xFF6E6E68);
  static const Color darkTextDisabled = Color(0xFF5A5855);
  static const Color darkBorder = Color(0xFF3A3A36);
  static const Color darkBorderGhost = Color(0xFF2E2E2B);
  static const Color darkError = Color(0xFFE57373);

  // ── Theme-aware helper: ShunShiColors.of(context).textPrimary ──
  static ShunShiColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkInstance : _lightInstance;
  }

  // ── Instance fields (used by of(context)) ──
  final Color primaryVal;
  final Color primaryContainerVal;
  final Color primaryLightVal;
  final Color backgroundVal;
  final Color surfaceVal;
  final Color surfaceContainerLowVal;
  final Color surfaceContainerLowestVal;
  final Color textPrimaryVal;
  final Color textSecondaryVal;
  final Color textTertiaryVal;
  final Color textDisabledVal;
  final Color borderVal;
  final Color borderGhostVal;
  final Color dividerVal;
  final Color cardVal;
  final Color warmVal;
  final Color calmVal;
  final Color errorVal;

  const ShunShiColors._instance({
    required this.primaryVal,
    required this.primaryContainerVal,
    required this.primaryLightVal,
    required this.backgroundVal,
    required this.surfaceVal,
    required this.surfaceContainerLowVal,
    required this.surfaceContainerLowestVal,
    required this.textPrimaryVal,
    required this.textSecondaryVal,
    required this.textTertiaryVal,
    required this.textDisabledVal,
    required this.borderVal,
    required this.borderGhostVal,
    required this.dividerVal,
    required this.cardVal,
    required this.warmVal,
    required this.calmVal,
    required this.errorVal,
  });

  static const _lightInstance = ShunShiColors._instance(
    primaryVal: primary,
    primaryContainerVal: primaryContainer,
    primaryLightVal: primaryLight,
    backgroundVal: background,
    surfaceVal: surface,
    surfaceContainerLowVal: surfaceContainerLow,
    surfaceContainerLowestVal: surfaceContainerLowest,
    textPrimaryVal: Color(0xFF1C1C19),
    textSecondaryVal: Color(0xFF6B7B7D),
    textTertiaryVal: Color(0xFF9CA3A5),
    textDisabledVal: Color(0xFFB5BBBD),
    borderVal: Color(0x331C1C19),
    borderGhostVal: Color(0x331C1C19),
    dividerVal: Color(0x1A1C1C19),
    cardVal: Color(0xFFFFFFFF),
    warmVal: Color(0xFFD4A574),
    calmVal: Color(0xFF9BB8C9),
    errorVal: Color(0xFFB85450),
  );

  static const _darkInstance = ShunShiColors._instance(
    primaryVal: darkPrimary,
    primaryContainerVal: Color(0xFF2D5A3D),
    primaryLightVal: Color(0xFFC5D1BB),
    backgroundVal: darkBackground,
    surfaceVal: darkSurface,
    surfaceContainerLowVal: darkSurfaceContainerLow,
    surfaceContainerLowestVal: darkSurfaceContainerLowest,
    textPrimaryVal: darkTextPrimary,
    textSecondaryVal: darkTextSecondary,
    textTertiaryVal: darkTextTertiary,
    textDisabledVal: darkTextDisabled,
    borderVal: darkBorderGhost,
    borderGhostVal: darkBorderGhost,
    dividerVal: darkBorder,
    cardVal: darkSurfaceContainerLowest,
    warmVal: Color(0xFFC4956A),
    calmVal: Color(0xFF8AAABB),
    errorVal: darkError,
  );
}

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier instance = ThemeNotifier._();
  ThemeNotifier._();
  ThemeNotifier(); // keep public constructor for compatibility

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0; // default: light (dark mode not fully ready)
    _mode = ThemeMode.values[index.clamp(0, 2)];
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> toggle() async {
    // cycle: light → dark → system → light
    final next = ThemeMode.values[((mode.index + 1) % 3)];
    await setMode(next);
  }
}

class ShunShiTypography {
  // ── 标题字体：Noto Serif SC（"Voice of Wisdom"）──
  static const String serifFamily = 'NotoSerifSC';
  // ── 正文字体：Noto Sans SC（Notion风格系统字体）──
  static const String sansFamily = 'NotoSansSC';
  
  // Display 级 — 季节问候、大标题
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w300,
    color: ShunShiColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
    fontFamily: serifFamily,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.3,
    fontFamily: serifFamily,
  );
  
  // Headline 级 — 页面标题
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: ShunShiColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
    fontFamily: serifFamily,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ShunShiColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
    fontFamily: serifFamily,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ShunShiColors.textPrimary,
    height: 1.3,
    fontFamily: serifFamily,
  );
  
  // Title 级
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
    fontFamily: sansFamily,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
    fontFamily: sansFamily,
  );
  
  // Body 级 — 正文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textPrimary,
    height: 1.6,
    fontFamily: sansFamily,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textPrimary,
    height: 1.6,
    fontFamily: sansFamily,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textSecondary,
    height: 1.5,
    fontFamily: sansFamily,
  );
  
  // Label 级 — 高端印刷感，letter-spacing 加大
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
    fontFamily: sansFamily,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ShunShiColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.5,
    fontFamily: sansFamily,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textTertiary,
    height: 1.4,
    letterSpacing: 0.3,
    fontFamily: sansFamily,
  );
  
  // Serif 辅助 — 用于卡片内标题
  static const TextStyle serifTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ShunShiColors.textPrimary,
    height: 1.3,
    fontFamily: serifFamily,
  );
  
  static const TextStyle serifBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: ShunShiColors.textSecondary,
    height: 1.7,
    fontFamily: serifFamily,
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
  static const double breath = 64; // Breathing spacing — generous whitespace
  
  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double listItemPadding = 14;
}

class ShunShiRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(999));
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

class ShunShiShadows {
  static const List<BoxShadow> none = [];
  
  // Notion 4-layer card shadow: soft, warm, multi-layer
  static const List<BoxShadow> ambient = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 4), blurRadius: 18, spreadRadius: 0),
    BoxShadow(color: Color(0x07000000), offset: Offset(0, 2), blurRadius: 7.85, spreadRadius: 0),
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 0.8), blurRadius: 2.93, spreadRadius: 0),
    BoxShadow(color: Color(0x03000000), offset: Offset(0, 0.175), blurRadius: 1.04, spreadRadius: 0),
  ];
  
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x06000000), offset: Offset(0, 2), blurRadius: 8, spreadRadius: 0),
  ];
  
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 4), blurRadius: 16, spreadRadius: 0),
  ];
  
  // 浮动元素（FAB、Bottom Sheet）— Notion deep shadow 5-layer
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x03000000), offset: Offset(0, 1), blurRadius: 3, spreadRadius: 0),
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 3), blurRadius: 7, spreadRadius: 0),
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 7), blurRadius: 15, spreadRadius: 0),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 14), blurRadius: 28, spreadRadius: 0),
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 23), blurRadius: 52, spreadRadius: 0),
  ];
}

// ── 玻璃态（Glassmorphism）── 用于 AI 模块和浮动覆盖层
class ShunShiGlass {
  static BoxDecoration glassmorphism({Color? tintColor}) {
    return BoxDecoration(
      color: (tintColor ?? ShunShiColors.surface).withValues(alpha: 0.7),
      borderRadius: ShunShiRadius.cardRadius,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }
  
  // ClipRRect + BackdropFilter 配合使用
  static double blurSigma = 16.0;
}

class ShunShiTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: ShunShiColors.primary,
        onPrimary: Colors.white,
        primaryContainer: ShunShiColors.primaryContainer,
        secondary: ShunShiColors.secondary,
        onSecondary: Colors.white,
        surface: ShunShiColors.surface,
        onSurface: ShunShiColors.textPrimary,
        surfaceContainerLowest: ShunShiColors.surfaceContainerLowest,
        surfaceContainerLow: ShunShiColors.surfaceContainerLow,
        error: ShunShiColors.error,
        outline: ShunShiColors.borderGhost,
        outlineVariant: Color(0xFFC1C9C0),
      ),
      scaffoldBackgroundColor: ShunShiColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: ShunShiColors.background,
        foregroundColor: ShunShiColors.textPrimary,
        elevation: 0,
        centerTitle: false,  // Left-aligned, magazine style
        titleTextStyle: ShunShiTypography.headlineSmall.copyWith(
          fontFamily: ShunShiTypography.serifFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: ShunShiColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.cardRadius,
          side: BorderSide(color: ShunShiColors.border),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunShiColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: ShunShiRadius.buttonRadius,
          ),
          textStyle: ShunShiTypography.labelLarge,
          // 微妙渐变感 — ink-drop quality
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShunShiColors.primary,
          side: BorderSide(color: ShunShiColors.borderGhost),
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
        fillColor: ShunShiColors.surfaceContainerLow,
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
          borderSide: BorderSide(color: ShunShiColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ShunShiColors.surfaceContainerLow,
        selectedColor: ShunShiColors.primaryLight.withValues(alpha: 0.15),
        labelStyle: ShunShiTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.chipRadius,
        ),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ShunShiColors.background,
        indicatorColor: ShunShiColors.primaryLight.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ShunShiColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: ShunShiRadius.bottomSheetRadius,
        ),
      ),
      // 全局去掉涟漪效果的硬边
      splashFactory: InkRipple.splashFactory,
      highlightColor: ShunShiColors.primary.withValues(alpha: 0.05),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: ShunShiColors.darkPrimary,
        onPrimary: Colors.white,
        primaryContainer: ShunShiColors.darkPrimary.withValues(alpha: 0.2),
        secondary: ShunShiColors.darkSecondary,
        onSecondary: Colors.white,
        surface: ShunShiColors.darkSurface,
        onSurface: ShunShiColors.darkTextPrimary,
        surfaceContainerLowest: ShunShiColors.darkSurfaceContainerLowest,
        surfaceContainerLow: ShunShiColors.darkSurfaceContainerLow,
        error: ShunShiColors.darkError,
        outline: ShunShiColors.darkBorderGhost,
        outlineVariant: ShunShiColors.darkBorder,
      ),
      scaffoldBackgroundColor: ShunShiColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: ShunShiColors.darkBackground,
        foregroundColor: ShunShiColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ShunShiColors.darkSurfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.cardRadius),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunShiColors.darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShunShiColors.darkPrimary,
          side: BorderSide(color: ShunShiColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.buttonRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ShunShiColors.darkPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShunShiColors.darkSurfaceContainerLow,
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
          borderSide: BorderSide(color: ShunShiColors.darkPrimary.withValues(alpha: 0.3), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ShunShiColors.darkSurfaceContainerLow,
        selectedColor: ShunShiColors.darkPrimary.withValues(alpha: 0.15),
        labelStyle: ShunShiTypography.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.chipRadius),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ShunShiColors.darkBackground,
        indicatorColor: ShunShiColors.darkPrimary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ShunShiTypography.labelMedium.copyWith(color: ShunShiColors.darkPrimary);
          }
          return ShunShiTypography.labelMedium.copyWith(color: ShunShiColors.darkTextTertiary);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: ShunShiColors.darkBorderGhost,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ShunShiColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: ShunShiRadius.bottomSheetRadius),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: ShunShiColors.darkPrimary.withValues(alpha: 0.05),
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
