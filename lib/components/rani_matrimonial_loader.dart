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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF750000)),
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      message,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF26121B),
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
