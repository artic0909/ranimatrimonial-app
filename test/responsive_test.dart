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
import 'package:ranimatrimonial_app/screens/connections/connection_request.dart';
import 'package:ranimatrimonial_app/screens/connections/accepted_screen.dart';
import 'package:ranimatrimonial_app/screens/connections/declined_screen.dart';
import 'package:ranimatrimonial_app/screens/connections/rejected_screen.dart';
import 'package:ranimatrimonial_app/screens/wallet/wallet_screen.dart';
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
        await tester.pump(const Duration(milliseconds: 200));

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
        await tester.pump(const Duration(milliseconds: 200));

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint("OVERFLOW ERROR ON $size: ${err.message}");
          debugPrint("FULL DIAG: ${err.toDiagnosticsNode().toStringDeep()}");
          for (final d in err.diagnostics) {
            debugPrint("DIAG: $d");
          }
        }
        expect(err, isNull, reason: "Overflow on size $size");

        // Verify Near Me tab pill is present and switchable
        final nearMeTab = find.textContaining('Near Me');
        expect(nearMeTab, findsOneWidget);
        await tester.tap(nearMeTab);
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Main navigation screen fits all screen sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(const RaniMainNavigationScreen()));
        await tester.pump(const Duration(milliseconds: 500));

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
        await tester.pump(const Duration(milliseconds: 500));

        // Tap hamburger menu in topbar
        final menuFinder = find.byTooltip('Menu');
        if (menuFinder.evaluate().isNotEmpty) {
          await tester.tap(menuFinder);
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(Drawer), findsOneWidget);
          expect(tester.takeException(), isNull, reason: "Sidebar overflow on $size");

          // Tap close button
          final closeFinder = find.byTooltip('Close Sidebar');
          if (closeFinder.evaluate().isNotEmpty) {
            await tester.tap(closeFinder, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 500));
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

    testWidgets('Connections screen with 4 tabs fits all phone sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(
          const RaniConnectionsScreen(showAppBar: true),
          size: size,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull, reason: 'Connections screen overflow on size $size');

        // Verify initial tabs exist
        expect(find.textContaining('Received'), findsOneWidget);
        expect(find.textContaining('Send'), findsOneWidget);

        // Switch to Send
        await tester.tap(find.textContaining('Send'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Accepted connections screen fits all phone sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(
          const RaniAcceptedConnectionsScreen(showAppBar: true),
          size: size,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull, reason: 'Accepted screen overflow on size $size');
      }
    });

    testWidgets('Declined connections screen fits all phone sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(
          const RaniDeclinedConnectionsScreen(showAppBar: true),
          size: size,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull, reason: 'Declined screen overflow on size $size');
      }
    });

    testWidgets('Website connection card renders without error with real API data', (tester) async {
      final sampleData = {
        'id': 'RM00026',
        'db_id': 39,
        'connection_id': 15,
        'first_name': 'Aman',
        'last_name': 'Islam',
        'age': 26,
        'height': '5\' 10" (177 cm)',
        'religion': 'Muslim',
        'community': 'Sunni',
        'mother_tongue': 'Hindi',
        'highest_qualification': 'B-Tech',
        'profession': 'asdasd',
        'company_name': 'asdasdasd',
        'annual_income': '4 - 5 Lakhs',
        'city': 'Howrah',
        'state': 'West Bengal',
        'diet': 'Non-Vegetarian',
        'photo': 'https://ranimatrimonial.com/img/male/correct1.png',
        'photos': ['https://ranimatrimonial.com/img/male/correct1.png'],
        'match_score': 87,
        'match_reasons': ['Muslim Religion', 'Howrah Resident'],
        'badge': '📤 Request Sent',
        'verified': false,
        'received_ago': '47 minutes ago',
        'status': 'pending',
        'is_accepted': false,
        'is_sent_by_me': true,
        'is_received_by_me': false,
        'wp_chat_status': null,
        'is_wp_chat_accepted': false,
        'is_wp_chat_received_by_me': false,
        'is_wp_chat_sent_by_me': false,
      };

      final size = const Size(390, 844);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(wrapScreen(
        Scaffold(
          body: RaniConnectionsScreen(
            showAppBar: true,
            initialTabIndex: 1,
            initialRequests: [sampleData],
          ),
        ),
        size: size,
      ));
      await tester.pump();
    });

    testWidgets('Royal Wallet screen with luxury Privilege Card fits all phone sizes without overflow', (tester) async {
      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapScreen(
          const RaniWalletScreen(showAppBar: true),
          size: size,
        ));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'Royal Wallet screen overflow on size $size');
      }
    });
  });
}
