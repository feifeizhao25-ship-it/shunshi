// Seasonal image widget for home page hero
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SeasonalImage extends StatelessWidget {
  final String? termOverride;
  const SeasonalImage({super.key, this.termOverride});

  @override
  Widget build(BuildContext context) {
    final term = termOverride ?? 'Clear & Bright';
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [ShunShiColors.primary, ShunShiColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(term, style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        )),
      ),
    );
  }
}
