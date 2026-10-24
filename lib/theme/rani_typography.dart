import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rani_colors.dart';

/// Rani Matrimonial Typography System
class RaniTypography {
  RaniTypography._();

  // Headings & Navigation (Playfair Display)
  static TextStyle displayLg({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 60,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 1.5,
        color: color,
      );

  static TextStyle displayMd({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -1.2,
        color: color,
      );

  static TextStyle headingXxl({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.11,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headingXl({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.75,
        color: color,
      );

  static TextStyle headingLg({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headingMd({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.56,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headingSm({Color color = RaniColors.ink}) => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle navigation({Color color = Colors.white}) => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
        color: color,
      );

  // Body & UI (Outfit)
  static TextStyle bodyXl({Color color = RaniColors.ink}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w300,
        height: 1.4,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodyLg({Color color = RaniColors.ink}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        height: 1.56,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodyMd({Color color = RaniColors.ink}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodySm({Color color = RaniColors.textMuted}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        height: 1.63,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodySmStrong({Color color = RaniColors.ink}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.63,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle button({Color color = Colors.white}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.43,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle buttonLarge({Color color = Colors.white}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle labelMd({Color color = RaniColors.ink}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.35,
        color: color,
      );

  static TextStyle labelSm({Color color = RaniColors.textMuted}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.53,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle captionUppercase({Color color = RaniColors.textMuted}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.6,
        color: color,
      );

  static TextStyle caption({Color color = RaniColors.textMuted}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0,
        color: color,
      );

  static TextTheme textTheme = TextTheme(
    displayLarge: displayLg(),
    displayMedium: displayMd(),
    displaySmall: headingXxl(),
    headlineLarge: headingXl(),
    headlineMedium: headingLg(),
    headlineSmall: headingMd(),
    titleLarge: headingSm(),
    titleMedium: navigation(),
    titleSmall: bodySmStrong(),
    bodyLarge: bodyLg(),
    bodyMedium: bodyMd(),
    bodySmall: bodySm(),
    labelLarge: button(),
    labelMedium: labelMd(),
    labelSmall: labelSm(),
  );
}
