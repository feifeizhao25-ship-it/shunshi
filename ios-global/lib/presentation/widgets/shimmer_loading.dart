


import 'package:flutter/material.dart';

/// 统一骨架屏组件
class ShimmerBlock extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFEAEAEA),
              Color(0xFFF5F5F5),
              Color(0xFFEAEAEA),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页骨架屏
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          const ShimmerBlock(height: 160, borderRadius: 20),
          const SizedBox(height: 24),
          // Greeting
          const ShimmerBlock(width: 180, height: 28, borderRadius: 8),
          const SizedBox(height: 8),
          const ShimmerBlock(width: 120, height: 16, borderRadius: 6),
          const SizedBox(height: 32),
          // Primary card
          const ShimmerBlock(height: 180, borderRadius: 20),
          const SizedBox(height: 16),
          // Secondary cards
          const ShimmerBlock(height: 64, borderRadius: 16),
          const SizedBox(height: 8),
          const ShimmerBlock(height: 64, borderRadius: 16),
          const SizedBox(height: 24),
          // Mood section
          const ShimmerBlock(width: 100, height: 16, borderRadius: 6),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(6, (_) => const ShimmerBlock(width: 56, height: 56, borderRadius: 28)),
          ),
        ],
      ),
    );
  }
}

/// 聊天骨架屏
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final isAI = i % 2 == 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAI) ...[
              const ShimmerBlock(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: 12),
              Expanded(child: ShimmerBlock(height: isAI ? 60 : 44, borderRadius: 16)),
            ] else ...[
              Expanded(child: ShimmerBlock(height: 44, borderRadius: 12)),
              const SizedBox(width: 12),
              const ShimmerBlock(width: 36, height: 36, borderRadius: 18),
            ],
          ],
        );
      },
    );
  }
}

/// 知识库骨架屏
class WellnessSkeleton extends StatelessWidget {
  const WellnessSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Personalized section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBlock(width: 80, height: 20, borderRadius: 6),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const ShimmerBlock(width: 150, height: 180, borderRadius: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerBlock(width: double.infinity, height: 38, borderRadius: 19),
          ),
          const SizedBox(height: 16),
          // Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(
                6,
                (_) => const ShimmerBlock(width: null, height: 200, borderRadius: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
