import 'package:flutter/material.dart';

const kHomeLoadingExplain = '正在准备今日。如果一直停在这里，返回后再打开一次。';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              kHomeLoadingExplain,
              key: Key('home-loading-explain'),
            ),
            const SizedBox(height: 12),
            _bone(160, 28),
            const SizedBox(height: 8),
            _bone(100, 16),
            const SizedBox(height: 32),
            _bone(null, 200, radius: 20),
            const SizedBox(height: 16),
            _bone(null, 56, radius: 16),
            const SizedBox(height: 8),
            _bone(null, 56, radius: 16),
          ],
        ),
      ),
    ),
  );

  Widget _bone(double? w, double h, {double radius = 8}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
