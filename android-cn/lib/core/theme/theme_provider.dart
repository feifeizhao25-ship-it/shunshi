import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shunshi_colors.dart';
import 'shunshi_spacing.dart';


/// Theme mode provider
enum AppThemeMode { light, dark, system }

class ThemeState {
  final AppThemeMode mode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const ThemeState({
    this.mode = AppThemeMode.system,
    required this.lightTheme,
    required this.darkTheme,
  });

  ThemeData get theme => mode == AppThemeMode.dark ? darkTheme : lightTheme;
  bool get isDark => mode == AppThemeMode.dark;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(ThemeState(
          lightTheme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
        ));

  void setMode(AppThemeMode mode) {
    state = ThemeState(
      mode: mode,
      lightTheme: state.lightTheme,
      darkTheme: state.darkTheme,
    );
  }

  void toggleTheme() {
    final newMode = state.mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    setMode(newMode);
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: ShunshiColors.primary,
        onPrimary: Colors.white,
        secondary: ShunshiColors.warm,
        tertiary: ShunshiColors.calm,
        surface: ShunshiColors.surface,
        onSurface: ShunshiColors.textPrimary,
        error: ShunshiColors.error,
        onError: ShunshiColors.textPrimary,
        outline: ShunshiColors.border,
        surfaceContainerHighest: ShunshiColors.surfaceDim,
      ),
      scaffoldBackgroundColor: ShunshiColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: ShunshiColors.surface,
        foregroundColor: ShunshiColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ShunshiColors.surfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunshiColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.lg,
            vertical: ShunshiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShunshiColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.md,
            vertical: ShunshiSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShunshiColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.lg,
          vertical: ShunshiSpacing.md,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShunshiColors.surface,
        selectedItemColor: ShunshiColors.primary,
        unselectedItemColor: ShunshiColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: ShunshiDarkColors.primary,
        onPrimary: ShunshiDarkColors.background,
        secondary: ShunshiDarkColors.warm,
        tertiary: ShunshiDarkColors.calm,
        surface: ShunshiDarkColors.surface,
        onSurface: ShunshiDarkColors.textPrimary,
        error: ShunshiDarkColors.error,
        onError: ShunshiDarkColors.textPrimary,
        outline: ShunshiDarkColors.border,
        surfaceContainerHighest: ShunshiDarkColors.surfaceDim,
      ),
      scaffoldBackgroundColor: ShunshiDarkColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: ShunshiDarkColors.surface,
        foregroundColor: ShunshiDarkColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ShunshiDarkColors.surfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunshiDarkColors.primary,
          foregroundColor: ShunshiDarkColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.lg,
            vertical: ShunshiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShunshiDarkColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.md,
            vertical: ShunshiSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShunshiDarkColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShunshiSpacing.radiusXL),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ShunshiSpacing.lg,
          vertical: ShunshiSpacing.md,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShunshiDarkColors.surface,
        selectedItemColor: ShunshiDarkColors.primary,
        unselectedItemColor: ShunshiDarkColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDark;
});
