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

/// Dedicated Content-Wise Skeleton for the Full-Image NEW Match Card
class RaniSkeletonMatchScreen extends StatelessWidget {
  const RaniSkeletonMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFFE4DDD2),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Top-left match score badge placeholder
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 100,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Top-right heart circle button placeholder
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Bottom Gradient Overlay & details
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF260003).withValues(alpha: 0.45),
                        const Color(0xFF150002).withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Verified seal & Photo count row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 85,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Photo count capsule badge placeholder
                          Container(
                            width: 76,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Age • Religion • Profession placeholder bar
                      Container(
                        width: 170,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location placeholder bar
                      Container(
                        width: 140,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Full width Connect Button placeholder
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF750000).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated Content-Wise Skeleton for Accepted & Shortlisted Candidate Lists
class RaniSkeletonCandidateList extends StatelessWidget {
  final bool isAcceptedTab;
  final int itemCount;

  const RaniSkeletonCandidateList({
    super.key,
    required this.isAcceptedTab,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return RaniSkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Candidate Thumbnail with photo count pill
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4DDD2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Photo count pill at bottom-right
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        width: 28,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Candidate Details & Actions Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Match Score pill + Verified checkmark placeholder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 72,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5B842).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE4DDD2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Name & Age placeholder
                      Row(
                        children: const [
                          Flexible(child: RaniSkeletonBox(height: 16, borderRadius: 4)),
                          SizedBox(width: 6),
                          RaniSkeletonBox(width: 32, height: 13, borderRadius: 4),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Profession & Income placeholder
                      const RaniSkeletonBox(width: 120, height: 12, borderRadius: 4),

                      const SizedBox(height: 5),

                      // Location placeholder
                      const RaniSkeletonBox(width: 90, height: 11, borderRadius: 4),

                      const SizedBox(height: 10),

                      // Actions Row: Specific to Accepted vs Shortlisted
                      if (isAcceptedTab) ...[
                        // Accepted Tab Actions: Connected status pill + "View Contact" button
                        Row(
                          children: [
                            Container(
                              width: 72,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF750000).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Shortlisted Tab Actions: Heart toggle button + "Connect Now" CTA button
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFCDD2)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF750000).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

