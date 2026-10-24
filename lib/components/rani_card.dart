import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';

/// Rani Standard Content Card
class RaniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const RaniCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RaniColors.surfaceLight,
        borderRadius: RaniSpacing.roundedLg,
        border: Border.all(
          color: RaniColors.gold,
          width: RaniSpacing.borderThin,
        ),
        boxShadow: RaniElevation.xl,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: RaniSpacing.roundedLg,
          onTap: onTap,
          child: Padding(
            padding: padding ?? RaniSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Rani Profile Card: Photo fills card with hero gradient overlay
class RaniProfileCard extends StatelessWidget {
  final String name;
  final String details;
  final String imagePath;
  final String? badge;
  final VoidCallback? onTap;

  const RaniProfileCard({
    super.key,
    required this.name,
    required this.details,
    required this.imagePath,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RaniColors.surfaceAlt,
        borderRadius: RaniSpacing.roundedLg,
        border: Border.all(
          color: RaniColors.gold,
          width: RaniSpacing.borderThin,
        ),
        boxShadow: RaniElevation.xl,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: RaniColors.surfaceAlt,
                  child: const Center(
                    child: Icon(Icons.person, color: RaniColors.gold, size: 48),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RaniColors.heroOverlay,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: RaniColors.goldGradient,
                      borderRadius: RaniSpacing.roundedFull,
                      boxShadow: RaniElevation.sm,
                    ),
                    child: Text(
                      badge!,
                      style: RaniTypography.captionUppercase(color: RaniColors.link),
                    ),
                  ),
                ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: RaniTypography.headingMd(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RaniSpacing.xxs),
                    Text(
                      details,
                      style: RaniTypography.bodySm(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rani Stat Card: Burgundy @15% fill with gold border and Playfair gold value
class RaniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const RaniStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: RaniSpacing.cardPadding,
      decoration: BoxDecoration(
        color: RaniColors.primary.withValues(alpha: 0.15),
        borderRadius: RaniSpacing.roundedLg,
        border: Border.all(
          color: RaniColors.gold,
          width: RaniSpacing.borderThin,
        ),
        boxShadow: RaniElevation.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: RaniColors.gold, size: 28),
            const SizedBox(height: RaniSpacing.xs),
          ],
          Text(
            value,
            textAlign: TextAlign.center,
            style: RaniTypography.headingLg(color: RaniColors.gold),
          ),
          const SizedBox(height: RaniSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: RaniTypography.bodySm(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
