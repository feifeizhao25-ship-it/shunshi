/*
SEASONS Design System - Core Components
Calm, minimal, nature-inspired
*/

import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

// ============== SoftButton ==============

/// A soft, calm button with gentle appearance
class SoftButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsets? padding;

  const SoftButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? SeasonsColors.skyBlue;
    final fgColor = textColor ?? Colors.white;
    
    final buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: isOutlined
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: fgColor,
                  side: BorderSide(color: bgColor, width: 1.5),
                  padding: buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _buildChild(context, isDark, fgColor, true),
              )
            : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  elevation: 0,
                  padding: buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _buildChild(context, isDark, fgColor, false),
              ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, bool isDark, Color fgColor, bool isOutlined) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(
            isOutlined 
                ? (Theme.of(context).brightness == Brightness.dark 
                    ? SeasonsColors.skyBlue 
                    : SeasonsColors.skyBlue)
                : Colors.white,
          ),
        ),
      );
    }
    
    return Text(
      text,
      style: SeasonsTypography.buttonLight.copyWith(
        color: isOutlined ? fgColor : Colors.white,
      ),
    );
  }
}

// ============== SoftCard ==============

/// A soft, elevated card with gentle shadows
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Material(
        color: backgroundColor ?? (isDark ? SeasonsColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============== CalmInput ==============

/// A calm, minimal input field
class CalmInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;

  const CalmInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onEditingComplete,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: SeasonsTypography.labelLight.copyWith(
              color: isDark ? SeasonsColors.textSecondaryDark : SeasonsColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          autofocus: autofocus,
          style: SeasonsTypography.bodyLight.copyWith(
            color: isDark ? SeasonsColors.textPrimaryDark : SeasonsColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? SeasonsColors.darkCard : SeasonsColors.surfaceLight,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ============== ContentTile ==============

/// A minimal content tile for lists
class ContentTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? leadingEmoji;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const ContentTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingEmoji,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Leading
              if (leadingEmoji != null)
                Text(leadingEmoji!, style: const TextStyle(fontSize: 24))
              else if (leading != null)
                leading!,
              if (leading != null || leadingEmoji != null)
                const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SeasonsTypography.bodyLight.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? SeasonsColors.textPrimaryDark : SeasonsColors.textPrimaryLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: SeasonsTypography.bodySmallLight.copyWith(
                          color: isDark ? SeasonsColors.textSecondaryDark : SeasonsColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ============== QuoteCard ==============

/// A beautiful card for quotes and reflections
class QuoteCard extends StatelessWidget {
  final String quote;
  final String? author;
  final Widget? trailing;
  final VoidCallback? onTap;

  const QuoteCard({
    super.key,
    required this.quote,
    this.author,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote mark
          Text(
            '❝',
            style: TextStyle(
              fontSize: 40,
              color: SeasonsColors.skyBlue.withValues(alpha: 0.5),
              height: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          
          // Quote text
          Text(
            quote,
            style: (isDark ? SeasonsTypography.quoteDark : SeasonsTypography.quoteLight).copyWith(
              fontSize: 18,
            ),
          ),
          
          if (author != null) ...[
            const SizedBox(height: 12),
            Text(
              '— $author',
              style: SeasonsTypography.captionLight.copyWith(
                color: isDark ? SeasonsColors.textSecondaryDark : SeasonsColors.textSecondaryLight,
              ),
            ),
          ],
          
          if (trailing != null) ...[
            const SizedBox(height: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ============== ReflectionCard ==============

/// A card for reflection prompts
class ReflectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final ValueChanged<String>? onSelected;
  final String? selectedOption;

  const ReflectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    this.onSelected,
    this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(title, style: SeasonsTypography.h3Light),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: SeasonsTypography.bodySmallLight,
            ),
          ],
          const SizedBox(height: 20),
          
          // Options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = option == selectedOption;
              return _OptionChip(
                label: option,
                isSelected: isSelected,
                onTap: () => onSelected?.call(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? SeasonsColors.skyBlueLight : SeasonsColors.warmSandLight,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: SeasonsTypography.bodySmallLight.copyWith(
                color: isSelected ? SeasonsColors.skyBlueDark : SeasonsColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== SeasonCard ==============

/// A card showing season information
class SeasonCard extends StatelessWidget {
  final String season;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SeasonCard({
    super.key,
    required this.season,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final seasonData = _getSeasonData(season);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: seasonData.color,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seasonData.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  season,
                  style: SeasonsTypography.labelLight.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: SeasonsTypography.h3Light.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SeasonData _getSeasonData(String season) {
    switch (season.toLowerCase()) {
      case 'spring':
        return _SeasonData('🌸', SeasonsColors.spring);
      case 'summer':
        return _SeasonData('☀️', SeasonsColors.summer);
      case 'autumn':
        return _SeasonData('🍂', SeasonsColors.autumn);
      case 'winter':
        return _SeasonData('❄️', SeasonsColors.winter);
      default:
        return _SeasonData('🌿', SeasonsColors.softSage);
    }
  }
}

class _SeasonData {
  final String emoji;
  final Color color;
  
  _SeasonData(this.emoji, this.color);
}
