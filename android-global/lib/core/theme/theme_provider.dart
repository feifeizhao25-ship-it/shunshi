import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seasons_colors.dart';
import 'seasons_spacing.dart';

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
        primary: SeasonsColors.primary,
        onPrimary: Colors.white,
        secondary: SeasonsColors.warm,
        tertiary: SeasonsColors.sage,
        surface: SeasonsColors.surface,
        onSurface: SeasonsColors.textPrimary,
        error: SeasonsColors.error,
        onError: SeasonsColors.textPrimary,
        outline: SeasonsColors.border,
        surfaceContainerHighest: SeasonsColors.surfaceDim,
      ),
      scaffoldBackgroundColor: SeasonsColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: SeasonsColors.surface,
        foregroundColor: SeasonsColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SeasonsColors.surfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SeasonsColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SeasonsSpacing.radiusXL),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SeasonsColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.md,
            vertical: SeasonsSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SeasonsColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusXL),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.lg,
          vertical: SeasonsSpacing.md,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SeasonsColors.surface,
        selectedItemColor: SeasonsColors.primary,
        unselectedItemColor: SeasonsColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
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
        primary: SeasonsDarkColors.primary,
        onPrimary: SeasonsDarkColors.background,
        secondary: SeasonsDarkColors.warm,
        tertiary: SeasonsDarkColors.sage,
        surface: SeasonsDarkColors.surface,
        onSurface: SeasonsDarkColors.textPrimary,
        error: SeasonsDarkColors.error,
        onError: SeasonsDarkColors.textPrimary,
        outline: SeasonsDarkColors.border,
        surfaceContainerHighest: SeasonsDarkColors.surfaceDim,
      ),
      scaffoldBackgroundColor: SeasonsDarkColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: SeasonsDarkColors.surface,
        foregroundColor: SeasonsDarkColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SeasonsDarkColors.surfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SeasonsDarkColors.primary,
          foregroundColor: SeasonsDarkColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SeasonsSpacing.radiusXL),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SeasonsDarkColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.md,
            vertical: SeasonsSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SeasonsDarkColors.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusXL),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.lg,
          vertical: SeasonsSpacing.md,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SeasonsDarkColors.surface,
        selectedItemColor: SeasonsDarkColors.primary,
        unselectedItemColor: SeasonsDarkColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
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
