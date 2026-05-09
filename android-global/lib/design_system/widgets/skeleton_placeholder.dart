// Skeleton Placeholder Widgets
// Reusable shimmer-based skeleton components for loading states

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper with theme-aware colors
class _ShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _ShimmerWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Card-shaped skeleton (content cards, recommendation cards)
class SkeletonCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  const SkeletonCard({
    super.key,
    this.height = 120,
    this.borderRadius = 16,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// List tile skeleton (avatar + 2 text lines)
class SkeletonListTile extends StatelessWidget {
  final bool hasAvatar;
  final int textLines;
  const SkeletonListTile({
    super.key,
    this.hasAvatar = true,
    this.textLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (hasAvatar) ...[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  if (textLines > 2) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paragraph skeleton (2-3 lines of text)
class SkeletonText extends StatelessWidget {
  final int lines;
  const SkeletonText({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines, (i) {
            final isLast = i == lines - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: i < lines - 1 ? 8 : 0),
              child: FractionallySizedBox(
                widthFactor: isLast ? 0.6 : 1.0,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Circle skeleton (for avatars)
class SkeletonCircle extends StatelessWidget {
  final double radius;
  const SkeletonCircle({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Full-page skeleton for list pages
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index)? itemBuilder;
  const SkeletonListView({super.key, this.itemCount = 6, this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: itemBuilder!,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}

/// Profile page skeleton
class SkeletonProfilePage extends StatelessWidget {
  const SkeletonProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header area
          _ShimmerWrapper(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                  CircleAvatar(radius: 40, backgroundColor: Colors.white),
                  SizedBox(height: 16),
                  SizedBox(width: 120, height: 20, child: ColoredBox(color: Colors.white)),
                  SizedBox(height: 8),
                  SizedBox(width: 80, height: 14, child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Cards
          ...List.generate(3, (_) => const SkeletonCard(height: 100)),
        ],
      ),
    );
  }
}

/// Chat page skeleton (message bubbles)
class SkeletonChatPage extends StatelessWidget {
  final int messageCount;
  const SkeletonChatPage({super.key, this.messageCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messageCount,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 1;
        return _ShimmerWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  const CircleAvatar(radius: 16, backgroundColor: Colors.white),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: isUser ? 160 : 200,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 16, backgroundColor: Colors.white),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
