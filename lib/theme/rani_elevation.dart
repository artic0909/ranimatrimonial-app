import 'package:flutter/material.dart';

/// Rani Matrimonial layered-micro elevation shadows.
class RaniElevation {
  RaniElevation._();

  /// SM: Inputs at rest (0 1 3 @10% + 0 1 2 -1 @10%)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000), // 10%
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// MD: Outline buttons, menus (0 4 6 -1 @10% + 0 2 4 -2 @10%)
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// XL: Primary buttons, raised cards (0 10 15 -3 @10% + 0 4 6 -4 @10%)
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// LG: Dialogs, bottom sheets (0 25 50 -12 @25%)
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x40000000), // 25%
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
  ];
}
