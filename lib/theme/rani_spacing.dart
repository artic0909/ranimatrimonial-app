import 'package:flutter/material.dart';

/// Rani Matrimonial spacing, radius, and border dimension tokens.
class RaniSpacing {
  RaniSpacing._();

  // Spacing (4px base)
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double xxxl = 32.0;
  static const double section = 36.0;
  static const double band = 48.0;

  // Screen Layout
  static const double screenPadding = 16.0;
  static const double sectionGap = 48.0;
  static const double minTouchTarget = 42.0;

  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);

  // Border Radii
  static const double radiusXs = 4.0; // Filled buttons
  static const double radiusMd = 12.0; // Inputs, snackbars
  static const double radiusLg = 16.0; // Cards, dialogs, bottom sheets
  static const double radiusFull = 9999.0; // Outline pills, chips, avatars

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Border Widths
  static const double borderThin = 1.0; // 1px gold borders, inputs, dividers
  static const double borderMedium = 2.0; // 2px dialogs, ghost buttons, focus
  static const double borderThick = 4.0; // 4px footer top border
}
