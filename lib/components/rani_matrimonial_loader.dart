import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean, standard matrimonial loader
class RaniMatrimonialLoader extends StatelessWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showBackground;

  const RaniMatrimonialLoader({
    super.key,
    this.size = 40,
    this.message,
    this.color,
    this.showBackground = false,
  });

  /// Compact mini version for buttons
  const RaniMatrimonialLoader.mini({
    super.key,
    this.size = 20,
    this.message,
    this.color,
    this.showBackground = false,
  });

  /// Helper to show full-screen loading dialog
  static void show(
    BuildContext context, {
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A0808).withValues(alpha: 0.94),
                        const Color(0xFF140202).withValues(alpha: 0.96),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5B842)), // Royal Gold
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          message,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
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
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF750000);

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size < 30 ? 2.2 : 3.2,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );

    if (message == null || message!.isEmpty) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 12),
        Text(
          message!,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A1010),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
