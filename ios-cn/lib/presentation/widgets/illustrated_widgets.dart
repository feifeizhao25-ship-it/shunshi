/// 图文并茂的通用组件：分类封面 + 带插画的列表卡片。
library;

import 'package:flutter/material.dart';
import '../../design_system/theme.dart';

class CategoryCover extends StatelessWidget {
  final String asset;
  final IconData icon;
  final String title;
  final String subtitle;
  const CategoryCover({super.key, required this.asset, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(decoration: BoxDecoration(color: ShunShiColors.primaryContainer)),
            Image.asset(asset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(
                          fontSize: 22, height: 1.25, color: Colors.white, fontWeight: FontWeight.w600,
                          fontFamily: ShunShiTypography.serifFamily,
                          shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                        )),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white.withValues(alpha: 0.92))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IllustratedCard extends StatelessWidget {
  final String? asset;
  final IconData fallbackIcon;
  final String title;
  final String desc;
  final String tip;
  final VoidCallback? onTap;
  const IllustratedCard({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.title,
    required this.desc,
    this.tip = '',
    this.onTap,
  });

  Widget _placeholder() => Container(
        width: 88,
        height: 88,
        color: ShunShiColors.primary.withValues(alpha: 0.08),
        child: Icon(fallbackIcon, size: 30, color: ShunShiColors.primary),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surfaceContainerLowest;
    final titleColor = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final bodyColor = isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;
    final borderColor = isDark ? ShunShiColors.darkBorder : ShunShiColors.textTertiary.withValues(alpha: 0.14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: asset == null
                    ? _placeholder()
                    : Image.asset(asset!, width: 88, height: 88, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 17, height: 1.35, fontWeight: FontWeight.w600, color: titleColor,
                      fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const SizedBox(height: 4),
                    Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.55, color: bodyColor)),
                    if (tip.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ShunShiColors.apricot.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.tips_and_updates_outlined, size: 16, color: ShunShiColors.secondary),
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text(tip, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? ShunShiColors.darkSecondary : ShunShiColors.secondary))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态：插画 + 标题 + 说明，替代单行灰字。
class IllustratedEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String asset;
  final Widget? action;
  const IllustratedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.asset = 'assets/images/wellness/empty_basket.webp',
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(asset, width: 240, height: 180, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 240, height: 180)),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 18, height: 1.4, fontWeight: FontWeight.w600,
            color: isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary,
            fontFamily: ShunShiTypography.serifFamily,
          )),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 14, height: 1.6,
            color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary,
          )),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// 文库内容卡片：顶部插画 + 分类标签 + 标题 + 摘要。
class LibraryCard extends StatelessWidget {
  final String asset;
  final String categoryLabel;
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback? onTap;
  const LibraryCard({super.key, required this.asset, required this.categoryLabel, required this.icon, required this.title, required this.desc, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? ShunShiColors.darkSurface : ShunShiColors.surfaceContainerLowest;
    final titleColor = isDark ? ShunShiColors.darkTextPrimary : ShunShiColors.textPrimary;
    final bodyColor = isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.14)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(decoration: BoxDecoration(color: ShunShiColors.primaryContainer)),
                    Image.asset(asset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 16, color: ShunShiColors.primary),
                          const SizedBox(width: 4),
                          Text(categoryLabel, style: const TextStyle(fontSize: 14, height: 1.2, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: titleColor, fontFamily: ShunShiTypography.serifFamily)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.55, color: bodyColor)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 文库分类 → 中文标签 / 封面
String libraryCategoryLabel(String? c) {
  switch (c) {
    case 'sleep': return '睡眠';
    case 'nutrition': return '饮食';
    case 'movement': return '运动';
    case 'mindfulness': return '静心';
    case 'seasonal': return '节气';
    default: return (c != null && RegExp(r'[一-鿿]').hasMatch(c)) ? c : '养生';
  }
}

String libraryCategoryCover(String? c) {
  switch (c) {
    case 'sleep': return 'assets/images/wellness/cover_sleep.webp';
    case 'nutrition': return 'assets/images/wellness/cover_tea.webp';
    case 'movement': return 'assets/images/wellness/cover_exercise.webp';
    case 'mindfulness': return 'assets/images/wellness/cat_sl_meditation.webp';
    case 'seasonal': return 'assets/images/wellness/cover_food_therapy.webp';
    default: return 'assets/images/wellness/cover_constitution.webp';
  }
}
