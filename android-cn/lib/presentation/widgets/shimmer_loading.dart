import 'package:flutter/material.dart';

/// 骨架屏组件 - 加载时显示
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  
  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 卡片骨架屏
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerLoading(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerLoading(height: 14),
            const SizedBox(height: 8),
            const ShimmerLoading(height: 14),
          ],
        ),
      ),
    );
  }
}

/// 列表骨架屏
class ShimmerList extends StatelessWidget {
  final int itemCount;
  
  const ShimmerList({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}
