// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tcc_admin_client/main.dart';

void main() {
  testWidgets('TCC Admin App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TccAdminApp());

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
