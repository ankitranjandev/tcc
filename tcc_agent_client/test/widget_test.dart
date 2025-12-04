// This is a basic Flutter widget test for TCC Agent App.

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_agent_client/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TCCAgentApp());

    // Verify that the app starts and loads
    expect(find.byType(TCCAgentApp), findsOneWidget);
  });
}
