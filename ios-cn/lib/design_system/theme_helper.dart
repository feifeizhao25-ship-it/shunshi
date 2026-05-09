import 'theme.dart';
import 'package:flutter/material.dart';

class AppColors {
  static Color primary(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkPrimary : ShunShiColors.primary;
  static Color secondary(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkSecondary : ShunShiColors.secondary;
  static Color background(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkBackground : ShunShiColors.background;
  static Color surface(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkSurface : ShunShiColors.surface;
  static Color surfaceContainerLowest(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkSurfaceContainerLowest : ShunShiColors.surfaceContainerLowest;
  static Color surfaceContainerLow(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkSurfaceContainerLow : ShunShiColors.surfaceContainerLow;
  static Color textPrimary(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
  static Color textSecondary(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;
  static Color textTertiary(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkTextTertiary : ShunShiColors.textTertiary;
  static Color textDisabled(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkTextDisabled : ShunShiColors.textDisabled;
  static Color border(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkBorder : ShunShiColors.border;
  static Color borderGhost(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkBorderGhost : ShunShiColors.borderGhost;
  static Color error(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? ShunShiColors.darkError : ShunShiColors.error;
}
