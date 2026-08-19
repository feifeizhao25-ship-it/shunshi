import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_text.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  color: AppColors.textPrimary,
                )
              else if (leading != null)
                leading!
              else
                const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: AppText.headlineSmall(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null)
                ...actions!
              else
                const SizedBox(width: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
