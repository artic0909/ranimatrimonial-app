import 'package:flutter/material.dart';

/// Reusable Skeleton Shimmer Loader for post-login screens in Rani Matrimonial.
/// Provides smooth, pulse-sweep shimmer cards for 2-column grids, lists, profile, and wallet.
class RaniSkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const RaniSkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEDE7DD),
    this.highlightColor = const Color(0xFFF9F6F0),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<RaniSkeletonShimmer> createState() => _RaniSkeletonShimmerState();
}

class _RaniSkeletonShimmerState extends State<RaniSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// Helper block for skeleton items
class RaniSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const RaniSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE4DDD2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 2-Column Grid of Skeleton Match Cards (Matches Home & Search screen grid)
class RaniSkeletonGrid extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const RaniSkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) => const RaniSkeletonMatchCard(),
      ),
    );
  }
}

/// Single Skeleton Match Card
class RaniSkeletonMatchCard extends StatelessWidget {
  const RaniSkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with heart & verified pill placeholders
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE4DDD2),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                // Top-right shortlist heart circle placeholder
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Bottom-left verified pill placeholder
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    width: 82,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & age bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(child: RaniSkeletonBox(height: 14, borderRadius: 4)),
                    SizedBox(width: 8),
                    RaniSkeletonBox(width: 28, height: 12, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 6),
                // Profession bar
                const RaniSkeletonBox(width: 100, height: 11, borderRadius: 4),
                const SizedBox(height: 4),
                // Location bar
                const RaniSkeletonBox(width: 70, height: 10, borderRadius: 4),
                const SizedBox(height: 10),
                // "View Profile" button bar
                Container(
                  width: double.infinity,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4DDD2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton List for Inbox / Conversations / Royal Inquiries
class RaniSkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const RaniSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFE8DE)),
            ),
            child: Row(
              children: [
                const RaniSkeletonBox(width: 52, height: 52, borderRadius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      RaniSkeletonBox(width: 130, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      RaniSkeletonBox(width: 180, height: 11, borderRadius: 4),
                      SizedBox(height: 6),
                      RaniSkeletonBox(width: 90, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
                const RaniSkeletonBox(width: 60, height: 28, borderRadius: 14),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton for Profile Screen & Profile Detail Screen
class RaniSkeletonProfile extends StatelessWidget {
  const RaniSkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top hero photo placeholder
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFE4DDD2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFE8DE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  RaniSkeletonBox(width: 160, height: 20, borderRadius: 6),
                  SizedBox(height: 8),
                  RaniSkeletonBox(width: 120, height: 13, borderRadius: 4),
                  SizedBox(height: 8),
                  RaniSkeletonBox(width: 200, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Details section cards
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFE8DE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    RaniSkeletonBox(width: 110, height: 16, borderRadius: 4),
                    SizedBox(height: 12),
                    RaniSkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    RaniSkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    RaniSkeletonBox(width: 180, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Wallet Screen
class RaniSkeletonWallet extends StatelessWidget {
  const RaniSkeletonWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance card placeholder
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFE4DDD2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons row placeholder
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DDD2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DDD2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Transaction history header placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                RaniSkeletonBox(width: 140, height: 18, borderRadius: 4),
                RaniSkeletonBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 14),
            // Transactions list
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFE8DE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        RaniSkeletonBox(width: 40, height: 40, borderRadius: 20),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RaniSkeletonBox(width: 110, height: 14, borderRadius: 4),
                            SizedBox(height: 5),
                            RaniSkeletonBox(width: 70, height: 11, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                    const RaniSkeletonBox(width: 65, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
