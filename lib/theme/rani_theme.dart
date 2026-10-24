import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rani_colors.dart';
import 'rani_spacing.dart';
import 'rani_typography.dart';

/// Rani Matrimonial Theme Data (Material 3).
class RaniTheme {
  RaniTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RaniColors.canvas,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: RaniTypography.textTheme,
      colorScheme: const ColorScheme.light(
        primary: RaniColors.primary,
        onPrimary: Colors.white,
        secondary: RaniColors.gold,
        onSecondary: RaniColors.link,
        surface: RaniColors.surfaceLight,
        onSurface: RaniColors.ink,
        error: RaniColors.accent1,
        onError: Colors.white,
        outline: RaniColors.neutral,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RaniColors.surfaceAlt,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: RaniTypography.headingMd(color: Colors.white),
        shape: const Border(
          bottom: BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RaniColors.surfaceAlt,
        selectedItemColor: RaniColors.gold,
        unselectedItemColor: Color(0xB3FFFFFF), // white 70%
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RaniColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: RaniSpacing.roundedXs,
          ),
          textStyle: RaniTypography.button(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RaniColors.ink,
          minimumSize: const Size.fromHeight(42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          side: const BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
          shape: const StadiumBorder(),
          textStyle: RaniTypography.button(color: RaniColors.ink),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RaniColors.primary,
          textStyle: RaniTypography.button(color: RaniColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RaniColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        hintStyle: RaniTypography.bodySm(color: RaniColors.textMuted),
        labelStyle: RaniTypography.labelMd(color: RaniColors.ink),
        border: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.neutral,
            width: RaniSpacing.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.neutral,
            width: RaniSpacing.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.primary,
            width: RaniSpacing.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.accent1,
            width: RaniSpacing.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.accent1,
            width: RaniSpacing.borderMedium,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: RaniSpacing.roundedMd,
          borderSide: const BorderSide(
            color: RaniColors.neutral,
            width: RaniSpacing.borderThin,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: RaniColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: RaniSpacing.roundedLg,
          side: const BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: RaniColors.surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RaniSpacing.roundedLg,
          side: const BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderMedium,
          ),
        ),
        titleTextStyle: RaniTypography.headingLg(color: Colors.white),
        contentTextStyle: RaniTypography.bodySm(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RaniColors.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: RaniSpacing.roundedMd,
          side: const BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
        ),
        contentTextStyle: RaniTypography.bodySm(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: RaniColors.primary,
        disabledColor: RaniColors.neutral.withValues(alpha: 0.3),
        shape: const StadiumBorder(
          side: BorderSide(
            color: RaniColors.gold,
            width: RaniSpacing.borderThin,
          ),
        ),
        labelStyle: RaniTypography.labelSm(color: RaniColors.ink),
        secondaryLabelStyle: RaniTypography.labelSm(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: RaniColors.gold,
        thickness: RaniSpacing.borderThin,
        space: 1,
      ),
    );
  }
}
