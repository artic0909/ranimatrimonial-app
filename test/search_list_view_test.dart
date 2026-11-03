import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranimatrimonial_app/screens/search/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Search screen top bar has clean layout: burger menu, un-truncated title, no back arrow, no restore icon', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: RaniSearchScreen(),
      ),
    );
    await tester.pump();

    // Verify Title
    expect(find.text('Search Profiles'), findsOneWidget);

    // Verify Burger menu icon exists
    expect(find.byIcon(CupertinoIcons.line_horizontal_3), findsOneWidget);

    // Verify NO back arrow button in top bar
    expect(find.byIcon(CupertinoIcons.arrow_left), findsNothing);

    // Verify NO restore/counterclockwise button in top bar
    expect(find.byIcon(CupertinoIcons.arrow_counterclockwise), findsNothing);

    // Verify Filter button exists
    expect(find.byIcon(CupertinoIcons.slider_horizontal_3), findsAtLeastNWidgets(1));
  });
}

