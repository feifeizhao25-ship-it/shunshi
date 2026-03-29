import 'package:seasons/design_system/design_system.dart';
/*
SEASONS Design System - Theme
Complete theme configuration
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

/// SEASONS Theme Configuration
class SeasonsTheme {
  // Private constructor
  SeasonsTheme._();

  // ============== Light Theme ==============
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Colors
      colorScheme: const ColorScheme.light(
        primary: SeasonsColors.skyBlue,
        onPrimary: Colors.white,
        primaryContainer: SeasonsColors.skyBlueLight,
        onPrimaryContainer: SeasonsColors.skyBlueDark,
        
        secondary: SeasonsColors.warmSand,
        onSecondary: SeasonsColors.textPrimaryLight,
        secondaryContainer: SeasonsColors.warmSandLight,
        onSecondaryContainer: SeasonsColors.warmSandDark,
        
        tertiary: SeasonsColors.softSage,
        onTertiary: Colors.white,
        tertiaryContainer: SeasonsColors.softSageLight,
        onTertiaryContainer: SeasonsColors.softSageDark,
        
        surface: SeasonsColors.surfaceLight,
        onSurface: SeasonsColors.textPrimaryLight,
        
        error: SeasonsColors.error,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: SeasonsColors.backgroundLight,
      
      // Text Theme
      textTheme: SeasonsTextTheme.lightTextTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: SeasonsColors.textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: SeasonsTypography.h3Light,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: SeasonsColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: SeasonsColors.skyBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: SeasonsTypography.buttonLight,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SeasonsColors.skyBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: SeasonsTypography.bodyLight.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SeasonsColors.skyBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: SeasonsColors.skyBlue, width: 1.5),
          textStyle: SeasonsTypography.buttonLight.copyWith(
            color: SeasonsColors.skyBlue,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SeasonsColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SeasonsColors.skyBlue, width: 2),
        ),
        hintStyle: SeasonsTypography.bodyLight.copyWith(
          color: SeasonsColors.textTertiaryLight,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: SeasonsColors.surfaceLight,
        selectedItemColor: SeasonsColors.skyBlue,
        unselectedItemColor: SeasonsColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: SeasonsColors.surfaceLight,
        indicatorColor: SeasonsColors.skyBlueLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SeasonsTypography.captionLight.copyWith(
              color: SeasonsColors.skyBlue,
              fontWeight: FontWeight.w600,
            );
          }
          return SeasonsTypography.captionLight;
        }),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: SeasonsColors.warmSandLight,
        selectedColor: SeasonsColors.skyBlueLight,
        labelStyle: SeasonsTypography.labelLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: SeasonsColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: SeasonsTypography.h2Light,
        contentTextStyle: SeasonsTypography.bodyLight,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SeasonsColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: SeasonsColors.textTertiaryLight.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: SeasonsColors.textSecondaryLight,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: SeasonsColors.skyBlue,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SeasonsColors.skyBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ============== Dark Theme ==============
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colors
      colorScheme: const ColorScheme.dark(
        primary: SeasonsColors.skyBlue,
        onPrimary: Colors.white,
        primaryContainer: SeasonsColors.skyBlueDark,
        onPrimaryContainer: SeasonsColors.skyBlueLight,
        
        secondary: SeasonsColors.warmSand,
        onSecondary: SeasonsColors.textPrimaryDark,
        secondaryContainer: SeasonsColors.warmSandDark,
        onSecondaryContainer: SeasonsColors.warmSandLight,
        
        tertiary: SeasonsColors.softSage,
        onTertiary: Colors.white,
        tertiaryContainer: SeasonsColors.softSageDark,
        onTertiaryContainer: SeasonsColors.softSageLight,
        
        surface: SeasonsColors.darkSurface,
        onSurface: SeasonsColors.textPrimaryDark,
        
        error: SeasonsColors.error,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: SeasonsColors.deepNight,
      
      // Text Theme
      textTheme: SeasonsTextTheme.darkTextTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: SeasonsColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: SeasonsTypography.h3Dark,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: SeasonsColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: SeasonsColors.skyBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: SeasonsTypography.buttonLight,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SeasonsColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SeasonsColors.skyBlue, width: 2),
        ),
        hintStyle: SeasonsTypography.bodyDark.copyWith(
          color: SeasonsColors.textTertiaryDark,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: SeasonsColors.darkSurface,
        selectedItemColor: SeasonsColors.skyBlue,
        unselectedItemColor: SeasonsColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: SeasonsColors.darkSurface,
        indicatorColor: SeasonsColors.skyBlueDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SeasonsTypography.captionDark.copyWith(
              color: SeasonsColors.skyBlue,
              fontWeight: FontWeight.w600,
            );
          }
          return SeasonsTypography.captionDark;
        }),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: SeasonsColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: SeasonsTypography.h2Dark,
        contentTextStyle: SeasonsTypography.bodyDark,
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
