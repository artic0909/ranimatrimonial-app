import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranimatrimonial_app/screens/splash_screen.dart';
import 'package:ranimatrimonial_app/screens/onboarding_screen.dart';
import 'package:ranimatrimonial_app/screens/login_screen.dart';
import 'package:ranimatrimonial_app/screens/welcome_screen.dart';
import 'package:ranimatrimonial_app/screens/home_screen.dart';
import 'package:ranimatrimonial_app/screens/profile_detail_screen.dart';
import 'package:ranimatrimonial_app/screens/search_screen.dart';
import 'package:ranimatrimonial_app/theme/rani_theme.dart';

void main() {
  final testSizes = [
    const Size(320, 568), // iPhone SE 1st gen / ultra-compact
    const Size(360, 640), // Small Android
    const Size(375, 667), // iPhone 8 / SE 2nd gen
    const Size(390, 844), // iPhone 13 / 14
    const Size(412, 915), // Google Pixel 7
    const Size(430, 932), // iPhone 14 / 15 Pro Max
  ];

  Widget wrapScreen(Widget screen, {double textScale = 1.0}) {
    return MaterialApp(
      theme: RaniTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
        ),
        child: screen,
      ),
    );
  }

  group('Screen responsiveness tests across all phone sizes', () {
    testWidgets('Splash screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniSplashScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Profile detail screen fits all screen sizes without overflow', (tester) async {
      final sampleProfile = {
        'name': 'Priyanka, 26',
        'profession': 'Doctor',
        'location': 'Kolkata, West Bengal',
        'image': 'assets/bride.png',
        'isVerified': true,
        'height': '5\'4"',
        'religion': 'Hindu',
        'community': 'Bengali',
        'about': 'Short bio about Priyanka.',
      };

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(RaniProfileDetailScreen(profile: sampleProfile)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Onboarding screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniOnboardingScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Welcome screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniWelcomeScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Home screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniHomeScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Login screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniLoginScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });

    testWidgets('Search screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniSearchScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on size $size');
      }
    });
  });
}
