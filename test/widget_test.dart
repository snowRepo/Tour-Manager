// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_manager/app.dart';

void main() {
  testWidgets('Welcome screen appears on first launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TourManagerApp(isFirstLaunch: true));
    await tester.pumpAndSettle();

    expect(find.text('Tour Manager'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
  });
}
