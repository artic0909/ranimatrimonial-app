import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranimatrimonial_app/screens/splash_screen.dart';
import 'package:ranimatrimonial_app/screens/onboarding_screen.dart';
import 'package:ranimatrimonial_app/screens/auth/login_screen.dart';
import 'package:ranimatrimonial_app/screens/welcome_screen.dart';
import 'package:ranimatrimonial_app/screens/home/home_screen.dart';
import 'package:ranimatrimonial_app/screens/profile_detail_screen.dart';
import 'package:ranimatrimonial_app/screens/search/search_screen.dart';
import 'package:ranimatrimonial_app/screens/auth/profile_completion_screen.dart';
import 'package:ranimatrimonial_app/screens/auth/aadhaar_verification_screen.dart';
import 'package:ranimatrimonial_app/screens/matches/matches_screen.dart';
import 'package:ranimatrimonial_app/screens/matches/details_screen.dart';
import 'package:ranimatrimonial_app/screens/main_navigation_screen.dart';
import 'package:ranimatrimonial_app/components/rani_skeleton_loader.dart';
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

  Widget wrapScreen(Widget screen, {double textScale = 1.0, Size? size}) {
    return MaterialApp(
      theme: RaniTheme.light,
      home: Builder(
        builder: (context) {
          final parentMq = MediaQuery.of(context);
          return MediaQuery(
            data: parentMq.copyWith(
              size: size ?? parentMq.size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: screen,
          );
        },
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

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
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

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Onboarding screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniOnboardingScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");

        // Drag to final slide (slide 2)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('Create Profile'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow on last slide on size $size');
      }
    });

    testWidgets('Welcome screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniWelcomeScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Home screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniHomeScreen(), size: size));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Login screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniLoginScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Search screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniSearchScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Profile completion screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniProfileCompletionScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Aadhaar verification screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniAadhaarVerificationScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Matches screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniMatchesScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Main navigation screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniMainNavigationScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");
      }
    });

    testWidgets('Match, Accepted, and Shortlisted content-wise skeletons fit all screen sizes', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // 1. Match Screen (NEW tab) Skeleton
        await tester.pumpWidget(wrapScreen(const Scaffold(body: RaniSkeletonMatchScreen())));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Match skeleton overflow on $size');

        // 2. Accepted Tab Skeleton
        await tester.pumpWidget(wrapScreen(const Scaffold(body: RaniSkeletonCandidateList(isAcceptedTab: true))));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Accepted skeleton overflow on $size');

        // 3. Shortlisted Tab Skeleton
        await tester.pumpWidget(wrapScreen(const Scaffold(body: RaniSkeletonCandidateList(isAcceptedTab: false))));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Shortlisted skeleton overflow on $size');
      }
    });

    testWidgets('Full-screen sidebar drawer opens without overflow on all sizes', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniMainNavigationScreen(), size: size));
        await tester.pumpAndSettle();

        // Tap hamburger menu in topbar
        final menuFinder = find.byTooltip('Menu');
        if (menuFinder.evaluate().isNotEmpty) {
          await tester.tap(menuFinder);
          await tester.pumpAndSettle();

          expect(find.byType(Drawer), findsOneWidget);
          expect(tester.takeException(), isNull, reason: "Sidebar overflow on $size");

          // Tap close button
          final closeFinder = find.byTooltip('Close Sidebar');
          if (closeFinder.evaluate().isNotEmpty) {
            await tester.tap(closeFinder, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Matches details screen fits all phone sizes without overflow', (tester) async {
      final sampleMatch = {
        'id': 'RM00024',
        'first_name': 'Rojina',
        'last_name': 'Islam',
        'age': 22,
        'height': "5' 4\"",
        'profession': 'Doctor',
        'city': 'Howrah',
        'state': 'West Bengal',
        'gender': 'Female',
        'marital_status': 'Never Married',
        'religion': 'Muslim',
        'community': 'Sunni',
        'sub_community': 'General',
        'gothra': 'N/A',
        'manglik': 'Non-Manglik',
        'diet': 'Non-Vegetarian',
        'blood_group': 'B+',
        'highest_qualification': 'MBBS',
        'working_with': 'Private Hospital',
        'annual_income': '₹ 15 - 20 Lakh',
        'father_profession': 'Business Owner',
        'mother_profession': 'Homemaker',
        'family_financial_status': 'Upper Middle Class',
        'match_score': 95,
        'photos': [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        ],
      };

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(
          RaniMatchDetailsScreen(
            profileId: 'RM00024',
            initialProfileData: sampleMatch,
          ),
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Match details overflow on size $size');
      }
    });
  });
}
