// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ready_to_marry/main.dart';

void main() {
  testWidgets('branded splash renders and app starts', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.text('Compatible'), findsOneWidget);
    expect(
      find.text('Meaningful connections, rooted in Africa.'),
      findsOneWidget,
    );
    expect(find.text('MEET WITH INTENTION'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Allow startup checks and the minimum brand-display time to complete.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
