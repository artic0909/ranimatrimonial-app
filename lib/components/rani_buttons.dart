import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';

/// Primary default button
class RaniPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  const RaniPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: RaniSpacing.xs),
        ],
        Text(
          text,
          style: RaniTypography.button(color: Colors.white),
        ),
      ],
    );

    return Container(
      width: width,
      height: 42,
      decoration: const BoxDecoration(
        boxShadow: RaniElevation.xl,
        borderRadius: RaniSpacing.roundedXs,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: RaniColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: RaniColors.neutral,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: RaniSpacing.roundedXs,
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

/// Gold CTA button: used on dark / photo backgrounds
class RaniGoldCtaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  const RaniGoldCtaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      decoration: const BoxDecoration(
        boxShadow: RaniElevation.xl,
        borderRadius: RaniSpacing.roundedXs,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: RaniColors.gold,
          foregroundColor: RaniColors.link,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: RaniSpacing.roundedXs,
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: RaniSpacing.xs),
            ],
            Text(
              text,
              style: RaniTypography.button(color: RaniColors.link),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outline button: transparent with 1px gold border
class RaniOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool onDark;
  final Widget? icon;
  final double? width;

  const RaniOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.onDark = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : RaniColors.ink;

    return Container(
      width: width,
      height: 42,
      decoration: const BoxDecoration(
        boxShadow: RaniElevation.md,
        borderRadius: RaniSpacing.roundedFull,
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          side: const BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: RaniSpacing.xs),
            ],
            Text(
              text,
              style: RaniTypography.button(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghost large button: transparent, 2px gold @70% border, height 56, pill
class RaniGhostLargeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  const RaniGhostLargeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: RaniColors.cream,
          side: BorderSide(
            color: RaniColors.gold.withValues(alpha: 0.7),
            width: RaniSpacing.borderMedium,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: RaniSpacing.xs),
            ],
            Text(
              text,
              style: RaniTypography.buttonLarge(color: RaniColors.cream),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text button: Burgundy text, Outfit 14/700
class RaniTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;

  const RaniTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: RaniColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: RaniSpacing.xs),
          ],
          Text(
            text,
            style: RaniTypography.button(color: RaniColors.primary),
          ),
        ],
      ),
    );
  }
}
