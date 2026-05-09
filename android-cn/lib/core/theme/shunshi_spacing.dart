/// 顺时间距系统 — 宽松、呼吸感
///
/// 核心原则：
/// - 比常规间距更宽松，让界面不拥挤
/// - 使用4dp基础网格，保持一致性
/// - pagePadding是页面水平安全边距，所有页面统一
class ShunshiSpacing {
  ShunshiSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double pagePadding = 20.0;

  // 组件内部
  static const double cardPadding = 20.0;
  static const double cardPaddingVertical = 16.0;
  static const double listItemPadding = 16.0;

  // 圆角
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;
}
