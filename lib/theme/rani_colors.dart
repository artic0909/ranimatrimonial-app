import 'package:flutter/material.dart';

/// Rani Matrimonial design system color tokens.
class RaniColors {
  RaniColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFF881337); // Burgundy CTA & active states
  static const Color link = Color(0xFF3B0000); // Text on gold buttons, deep accents
  static const Color canvas = Color(0xFFFDFBF7); // Scaffold background (cream)
  static const Color ink = Color(0xFF1A0000); // Heading text on cream, app bar, bottom nav
  static const Color surfaceAlt = Color(0xFF1A0000); // Alias for ink/dark surface
  static const Color gold = Color(0xFFD4AF37); // 1px borders, dividers, premium accents, gold CTA
  static const Color goldSecondary = Color(0xFFC59B27); // Gold gradient end
  static const Color accent1 = Color(0xFF750000); // Burgundy band start, error accent
  static const Color accent2 = Color(0xFF1E293B); // Slate decorative backgrounds
  static const Color cream = Color(0xFFF9F1D8); // Text/icons on dark, ghost button text
  static const Color accent4 = Color(0xFF475569); // Neutral depth
  static const Color neutral = Color(0xFFCBD5E1); // Input borders, disabled states
  static const Color textMuted = Color(0xFF695856); // Secondary text (light theme)
  static const Color surfaceLight = Colors.white; // Cards, input fill in light theme

  // Text Color Rule: Never use pure #000000 for text. Always use #1A0000.
  static const Color textPrimary = ink;
  static const Color textSecondary = textMuted;
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkMuted = cream;
  static const Color textHoverOnDark = Color(0xFFF27474);

  // Gradients
  /// Hero / photo overlay (bottom -> top): ink-burgundy 80% -> 20% at 50% -> transparent.
  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: [0.0, 0.5, 1.0],
    colors: [
      Color(0xCC1A0000), // ~80% ink
      Color(0x331A0000), // ~20% ink
      Colors.transparent,
    ],
  );

  /// Burgundy band: #750000 -> #3B0000, left to right.
  static const LinearGradient burgundyBand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      accent1, // #750000
      link,    // #3B0000
    ],
  );

  /// Gold shimmer / badge gradient: #D4AF37 -> #C59B27.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gold,
      goldSecondary,
    ],
  );

  // Optional Dark Theme Tokens
  static const Color darkBg = Color(0xFF130B0F);
  static const Color darkSurface = Color(0xFF211A1D);
  static const Color darkRaised = Color(0xFF2D2629);
  static const Color darkText = Color(0xFFFAF6F7);
  static const Color darkMuted = Color(0xFFA29D9F);
  static const Color darkBorder = Color(0xFF393235);
  static const Color darkAccent = Color(0xFFE23369);
  static const Color darkOnAccent = Color(0xFF0B0B0C);
}
