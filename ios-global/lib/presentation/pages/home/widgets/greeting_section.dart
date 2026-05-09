import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/theme_helper.dart';

class GreetingSection extends StatelessWidget {
  final String greeting;
  final String userName;
  final String shiChen;
  final String shiChenOrgan;
  final String constitution;
  const GreetingSection({
    super.key,
    required this.greeting,
    required this.userName,
    required this.shiChen,
    required this.shiChenOrgan,
    required this.constitution,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(greeting,
        style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
          height: 1.2,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text('$userName，$shiChen时 · $shiChenOrgan${constitution.isNotEmpty ? ' · $constitution质' : ''}',
        style: TextStyle(
          fontFamily: ShunShiTypography.sansFamily,
          fontSize: 15,
          color: AppColors.textSecondary(context),
        ),
      ),
    ],
  );
}
