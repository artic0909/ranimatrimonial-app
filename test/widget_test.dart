import 'package:flutter_test/flutter_test.dart';
import 'package:ranimatrimonial_app/main.dart';
import 'package:ranimatrimonial_app/screens/splash_screen.dart';

void main() {
  testWidgets('Rani Matrimonial App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RaniMatrimonialApp());

    // Verify that the splash screen is present.
    expect(find.byType(RaniSplashScreen), findsOneWidget);
    expect(find.text('Find Your Perfect Life Partner'), findsOneWidget);
  });
}
