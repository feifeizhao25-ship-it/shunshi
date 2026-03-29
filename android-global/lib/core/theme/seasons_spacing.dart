/// Seasons 间距系统 — 与国内版一致但更宽松
///
/// 国际版间距原则：
/// - 在国内版基础上微调，整体更宽松
/// - pagePadding更大（24 vs 20），更多留白
class SeasonsSpacing {
  SeasonsSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double pagePadding = 24.0;

  // 组件内部
  static const double cardPadding = 24.0;
  static const double cardPaddingVertical = 20.0;
  static const double listItemPadding = 20.0;

  // 圆角
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;
}
