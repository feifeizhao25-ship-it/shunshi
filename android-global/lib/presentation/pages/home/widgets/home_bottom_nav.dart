import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/theme_helper.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: const Color(0xFFE5E5EA), width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_rounded, 'Home', true, () {}),
            _navItem(context, Icons.chat_bubble_outline_rounded, 'Chat', false, () => context.push('/chat')),
            _navItem(context, Icons.book_outlined, 'Records', false, () => context.push('/diary')),
            _navItem(context, Icons.person_outline_rounded, 'Profile', false, () => context.push('/profile')),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? ShunShiColors.primary : AppColors.textTertiary(context), size: 24),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                color: active ? ShunShiColors.primary : AppColors.textTertiary(context),
                fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
}
