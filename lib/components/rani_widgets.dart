import 'package:flutter/material.dart';
import '../theme/rani_colors.dart';
import '../theme/rani_elevation.dart';
import '../theme/rani_spacing.dart';
import '../theme/rani_typography.dart';

/// 1px Gold Divider
class RaniGoldDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const RaniGoldDivider({
    super.key,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: RaniColors.gold,
      thickness: RaniSpacing.borderThin,
      height: 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Filter / Selection Chip
class RaniFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const RaniFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected?.call(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? RaniColors.primary : Colors.transparent,
          borderRadius: RaniSpacing.roundedFull,
          border: Border.all(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
          boxShadow: isSelected ? RaniElevation.sm : null,
        ),
        child: Text(
          label,
          style: isSelected
              ? RaniTypography.labelSm(color: Colors.white)
              : RaniTypography.labelSm(color: RaniColors.ink),
        ),
      ),
    );
  }
}

/// Burgundy Band: #750000 -> #3B0000 left to right
class RaniBurgundyBand extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const RaniBurgundyBand({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RaniSpacing.lg),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: RaniColors.burgundyBand,
        borderRadius: borderRadius ?? RaniSpacing.roundedLg,
        border: Border.all(
          color: RaniColors.gold,
          width: RaniSpacing.borderThin,
        ),
        boxShadow: RaniElevation.xl,
      ),
      child: child,
    );
  }
}

/// Footer-style Band: #1A0000 with 4px gold top border
class RaniFooterBand extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actionWidgets;

  const RaniFooterBand({
    super.key,
    this.title = 'Rani Matrimonial',
    this.subtitle = 'Find your perfect match with royal elegance and trusted connections.',
    this.actionWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: RaniColors.surfaceAlt,
        border: Border(
          top: BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThick,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        RaniSpacing.screenPadding,
        64,
        RaniSpacing.screenPadding,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: RaniTypography.headingLg(color: RaniColors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RaniSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              subtitle,
              style: RaniTypography.bodySm(color: RaniColors.cream),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: RaniSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.share),
              const SizedBox(width: RaniSpacing.md),
              _buildSocialIcon(Icons.favorite),
              const SizedBox(width: RaniSpacing.md),
              _buildSocialIcon(Icons.mail_outline),
              const SizedBox(width: RaniSpacing.md),
              _buildSocialIcon(Icons.call),
            ],
          ),
          if (actionWidgets != null) ...[
            const SizedBox(height: RaniSpacing.xl),
            ...actionWidgets!,
          ],
          const SizedBox(height: RaniSpacing.xxl),
          const RaniGoldDivider(),
          const SizedBox(height: RaniSpacing.md),
          Text(
            '© 2026 Rani Matrimonial. All rights reserved.',
            style: RaniTypography.caption(color: RaniColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: RaniColors.gold.withValues(alpha: 0.5),
          width: RaniSpacing.borderThin,
        ),
      ),
      child: Center(
        child: Icon(icon, color: RaniColors.cream, size: 20),
      ),
    );
  }
}

/// Helper function to show Rani-styled Dialog
Future<T?> showRaniDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  String? confirmText,
  VoidCallback? onConfirm,
  String? cancelText,
  VoidCallback? onCancel,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: RaniColors.surfaceAlt,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: RaniSpacing.roundedLg,
        side: const BorderSide(
          color: RaniColors.gold,
          width: RaniSpacing.borderMedium,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: RaniElevation.lg,
          borderRadius: RaniSpacing.roundedLg,
        ),
        padding: const EdgeInsets.all(RaniSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: RaniTypography.headingLg(color: Colors.white),
            ),
            const SizedBox(height: RaniSpacing.md),
            Text(
              content,
              style: RaniTypography.bodySm(color: Colors.white),
            ),
            const SizedBox(height: RaniSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    child: Text(
                      cancelText,
                      style: RaniTypography.button(color: RaniColors.cream),
                    ),
                  ),
                if (confirmText != null) ...[
                  const SizedBox(width: RaniSpacing.md),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RaniColors.gold,
                      foregroundColor: RaniColors.link,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: RaniSpacing.roundedXs,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                    child: Text(
                      confirmText,
                      style: RaniTypography.button(color: RaniColors.link),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
