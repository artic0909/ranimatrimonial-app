import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom royal matrimonial loader featuring interlocking golden rings,
/// pulsating royal heart knot, and radiant golden shimmer aura.
class RaniMatrimonialLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showBackground;

  const RaniMatrimonialLoader({
    super.key,
    this.size = 80,
    this.message,
    this.color,
    this.showBackground = false,
  });

  /// Compact mini spinner version for buttons and small cards
  const RaniMatrimonialLoader.mini({
    super.key,
    this.size = 24,
    this.message,
    this.color,
    this.showBackground = false,
  });

  /// Helper to show full-screen matrimonial loading dialog
  static void show(
    BuildContext context, {
    String message = 'Connecting Royal Hearts...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFF26121B).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4A034).withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RaniMatrimonialLoader(size: 84),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      message,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF3E5AB),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to hide the active loader
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  State<RaniMatrimonialLoader> createState() => _RaniMatrimonialLoaderState();
}

class _RaniMatrimonialLoaderState extends State<RaniMatrimonialLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget loader = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MatrimonialPainter(
            progress: _controller.value,
            goldColor: widget.color ?? const Color(0xFFE5B842),
          ),
        );
      },
    );

    if (widget.showBackground) {
      loader = Container(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x384E342E),
          border: Border.all(
            color: const Color(0xFFD4A034).withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Center(child: loader),
      );
    }

    if (widget.message != null && widget.message!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 12),
          Text(
            widget.message!,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE5B842),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loader;
  }
}

/// Custom painter for interlocking wedding rings with pulsating heart knot
class _MatrimonialPainter extends CustomPainter {
  final double progress;
  final Color goldColor;

  _MatrimonialPainter({
    required this.progress,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final strokeWidth = math.max(1.8, size.width * 0.065);

    // 1. Shimmering Golden Aura Glow
    final auraPaint = Paint()
      ..color = goldColor.withValues(
        alpha: 0.15 + 0.12 * math.sin(progress * 2 * math.pi),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.18);
    canvas.drawCircle(center, radius * 1.45, auraPaint);

    // Ring offset distances for interlocking
    final offsetDistance = radius * 0.58;
    final leftCenter = Offset(center.dx - offsetDistance, center.dy);
    final rightCenter = Offset(center.dx + offsetDistance, center.dy);

    // 2. Groom's Ring (Left Gold Ring with rotating spark)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFE5B842),
          const Color(0xFFFFF2B2),
          const Color(0xFFC79224),
          const Color(0xFF881337),
          const Color(0xFFE5B842),
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: leftCenter, radius: radius));

    canvas.drawCircle(leftCenter, radius, ringPaint);

    // 3. Bride's Ring (Right Gold Ring with counter-rotating shimmer)
    final brideRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFC79224),
          const Color(0xFFE5B842),
          const Color(0xFFFFF2B2),
          const Color(0xFF881337),
          const Color(0xFFC79224),
        ],
        transform: GradientRotation(-progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: rightCenter, radius: radius));

    canvas.drawCircle(rightCenter, radius, brideRingPaint);

    // 4. Diamond sparkle on top of the left ring
    final diamondAngle = progress * 2 * math.pi;
    final diamondPos = Offset(
      leftCenter.dx + radius * math.cos(diamondAngle),
      leftCenter.dy + radius * math.sin(diamondAngle),
    );
    final diamondPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(diamondPos, strokeWidth * 0.9, diamondPaint);

    final diamondGlow = Paint()
      ..color = const Color(0xFFFFF7C2).withValues(alpha: 0.75)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 2);
    canvas.drawCircle(diamondPos, strokeWidth * 1.6, diamondGlow);

    // 5. Pulsing Royal Matrimonial Heart Knot at the intersection
    final heartScale = 0.85 + 0.25 * math.sin(progress * 4 * math.pi);
    _drawHeart(
      canvas,
      center,
      size.width * 0.16 * heartScale,
      const Color(0xFFE5B842),
      const Color(0xFF9E1B32),
    );
  }

  void _drawHeart(
    Canvas canvas,
    Offset center,
    double size,
    Color strokeColor,
    Color fillColor,
  ) {
    final path = Path();
    final width = size;
    final height = size;

    final x = center.dx;
    final y = center.dy - height * 0.25;

    path.moveTo(x, y + height * 0.35);
    path.cubicTo(
      x - width * 0.5,
      y - height * 0.25,
      x - width * 0.6,
      y + height * 0.45,
      x,
      y + height * 0.95,
    );
    path.cubicTo(
      x + width * 0.6,
      y + height * 0.45,
      x + width * 0.5,
      y - height * 0.25,
      x,
      y + height * 0.35,
    );
    path.close();

    final heartFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, heartFill);

    final heartStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size * 0.1);
    canvas.drawPath(path, heartStroke);
  }

  @override
  bool shouldRepaint(covariant _MatrimonialPainter oldDelegate) => true;
}

