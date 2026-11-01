import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(title: const Text('Error'), backgroundColor: AppColors.background(context)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary(context)),
            const SizedBox(height: 16),
            Text('Page not found', style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/today'),
              child: const Text('Back to Today'),
            ),
          ],
        ),
      ),
    );
  }
}
