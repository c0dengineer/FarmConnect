import 'package:farmconnect/features/common/startup_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missing Firebase configuration shows setup instructions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StartupErrorScreen(
        error: UnsupportedError('Firebase is not configured yet'),
      ),
    ));

    expect(find.text('FarmConnect could not start'), findsOneWidget);
    expect(find.text('dart pub global run flutterfire_cli:flutterfire configure'), findsOneWidget);
    expect(find.text('Select your Firebase project and include Web.'), findsOneWidget);
  });

  testWidgets('other Firebase startup failures show technical details', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StartupErrorScreen(error: 'Firebase network failure'),
    ));

    expect(find.text('Firebase initialization failed. Check your Firebase configuration and restart the app.'),
        findsOneWidget);
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.text('Firebase network failure'), findsOneWidget);
  });
}
