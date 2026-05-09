# 顺时 ShunShi Design System

## 设计原则

- 东方自然风格
- 温和、不焦虑
- 不像医疗软件，不像效率工具，像生活助手

---

## Color Tokens

```dart
// main.dart 颜色定义
class AppColors {
  // 主色 - 青绿系
  static const Color primary = Color(0xFF4A7C6F);        // 主色
  static const Color primaryLight = Color(0xFF6B9E8F);   // 浅主色
  static const Color primaryDark = Color(0xFF2D5A4D);    // 深主色

  // 背景色 - 米白系
  static const Color background = Color(0xFFFAF8F5);    // 背景
  static const Color surface = Color(0xFFFFFFFF);         // 卡片表面
  static const Color surfaceVariant = Color(0xFFF5F2ED);  // 次表面

  // 点缀色
  static const Color accent = Color(0xFFE8A87C);          // 暖橙
  static const Color accentLight = Color(0xFFF5D6C1);    // 浅暖橙
  static const Color gold = Color(0xFFD4B896);            // 浅金
  static const Color blue = Color(0xFF8EB8C9);           // 淡蓝

  // 中性色
  static const Color textPrimary = Color(0xFF2C2C2C);    // 主文字
  static const Color textSecondary = Color(0xFF6B6B6B);  // 次文字
  static const Color textTertiary = Color(0xFF9B9B9B);   // 辅助文字
  static const Color textDisabled = Color(0xFFCCCCCC);  // 禁用文字

  // 边框与分割
  static const Color border = Color(0xFFE8E5E0);          // 边框
  static const Color divider = Color(0xFFF0EDEA);         // 分割线

  // 状态色（不推荐大面积使用红色警示）
  static const Color success = Color(0xFF6B9E8F);         // 成功（同主色）
  static const Color warning = Color(0xFFE8A87C);          // 警告（暖橙）
  static const Color error = Color(0xFFD4726A);            // 错误（柔和红）
  static const Color info = Color(0xFF8EB8C9);            // 信息（淡蓝）

  // 渐变
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [accent, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

---

## Typography

```dart
class AppTypography {
  // 字体家族
  static const String fontFamily = 'Noto Sans SC';
  static const String fontFamilyMedium = 'Noto Sans SC Medium';

  // 字号（支持大字号模式）
  static const double displayLarge = 32.0;   // 欢迎语
  static const double displayMedium = 28.0;  // 标题
  static const double headlineLarge = 24.0; // 页面标题
  static const double headlineMedium = 20.0; // 模块标题
  static const double titleLarge = 18.0;    // 卡片标题
  static const double titleMedium = 16.0;   // 列表标题
  static const double bodyLarge = 16.0;     // 正文大
  static const double bodyMedium = 14.0;    // 正文
  static const double bodySmall = 12.0;     // 辅助文字
  static const double labelLarge = 14.0;    // 按钮文字
  static const double labelMedium = 12.0;    // 小标签
  static const double caption = 11.0;       // 脚注

  // 行高
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // 字重
  static const FontWeight weightBold = FontWeight.w600;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightLight = FontWeight.w300;
}
```

---

## Spacing

```dart
class AppSpacing {
  // 基础单位 4px
  static const double unit = 4.0;

  // 间距
  static const double xxs = 4.0;   // 极小
  static const double xs = 8.0;   // 小
  static const double sm = 12.0;  // 中小
  static const double md = 16.0;  // 中
  static const double lg = 20.0;  // 中大
  static const double xl = 24.0;  // 大
  static const double xxl = 32.0; // 特大
  static const double xxxl = 48.0;// 极大

  // 页面边距
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double listItemPadding = 12.0;

  // 组件间距
  static const double betweenCards = 12.0;
  static const double betweenSections = 24.0;
  static const double betweenTitleContent = 8.0;
}
```

---

## Radius

```dart
class AppRadius {
  // 圆角（柔和）
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;   // 卡片默认
  static const double lg = 16.0;   // 大卡片
  static const double xl = 20.0;   // 弹窗
  static const double xxl = 28.0;  // 大弹窗
  static const double full = 9999.0; // 圆形

  // 预定义
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(full));
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}
```

---

## Shadow

```dart
class AppShadow {
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
```

---

## Button 样式

```dart
// 主按钮
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
}

// 变体
enum AppButtonVariant {
  primary,    // 主按钮（青绿色）
  secondary,  // 次按钮（边框+文字）
  ghost,      // 幽灵按钮（无边框）
  text,       // 文字按钮
}

// 尺寸
enum AppButtonSize {
  large,   // 高度 56px
  medium,  // 高度 48px (默认)
  small,   // 高度 36px
  mini,    // 高度 28px
}
```

---

## Card 样式

```dart
// 标准卡片
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? background;
  final BorderRadius? radius;
}

// 变体
- AppCard.elevated()   // 带阴影
- AppCard.outlined()   // 带边框
- AppCard.ghost()     // 无阴影无边框
- AppCard.interactive() // 可点击（点击反馈）
```

---

## Chips 样式

```dart
// 快捷回复 Chips
class AppChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final AppChipVariant variant;
}

enum AppChipVariant {
  defaultChip,   // 默认灰色
  primaryChip,   // 主色选中
  accentChip,    // 暖橙 accent
  voiceChip,    // 语音输入专用
}
```

---

## Bottom Navigation

```dart
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
}

class AppNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// 5 个固定 Tab
- 首页 (HomeOutline / HomeFilled)
- 对话 (ChatOutline / ChatFilled)
- 养生 (WellnessOutline / WellnessFilled)
- 家庭 (FamilyOutline / FamilyFilled)
- 我的 (ProfileOutline / ProfileFilled)

// 样式
- 选中：primary 颜色
- 未选中：textTertiary 颜色
- 图标大小：24px
- 文字大小：labelMedium
- 底部安全区自动适配
```

---

## Notice 样式

```dart
// 系统通知卡片
class AppNoticeCard extends StatelessWidget {
  final String title;
  final String? message;
  final AppNoticeType type;
  final VoidCallback? onDismiss;
}

enum AppNoticeType {
  info,     // 淡蓝背景
  success,  // 主色背景
  warning,  // 暖橙背景
  error,    // 柔和红背景
}
```

---

## SafeMode Card

```dart
// 情绪安全模式提示卡
class SafeModeCard extends StatelessWidget {
  final String title;
  final String message;
  final String? primaryAction;
  final VoidCallback? onPrimaryAction;
}
```

---

## 通用组件清单

| 组件名 | 用途 | 状态 |
|--------|------|------|
| AppButton | 按钮 | default/loading/disabled |
| AppCard | 卡片 | elevated/outlined/ghost |
| AppTextField | 输入框 | default/focus/error/disabled |
| AppChip | 标签/快捷回复 | default/selected |
| AppBottomNav | 底部导航 | - |
| AppNoticeCard | 通知卡片 | info/success/warning/error |
| AppEmptyState | 空状态 | - |
| AppErrorState | 错误状态 | - |
| AppLoading | 加载动画 | - |
| AppDivider | 分割线 | horizontal/vertical |
| AppAvatar | 头像 | withImage/placeholder |
| AppBadge | 徽章 | - |
| AppProgress | 进度条 | linear/circular |
| AppSwitch | 开关 | on/off |
| AppSlider | 滑动条 | - |

---

## Accessibility 规范

- 最小点击区域：44x44px
- 对比度：文字与背景对比度 ≥ 4.5:1
- 大字号模式：支持系统字体放大至 200%
- 语音友好：所有可点击元素有语义标签
- 暗色模式：支持（可选）
