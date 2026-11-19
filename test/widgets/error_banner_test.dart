import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/widgets/error_banner.dart';

void main() {
  testWidgets('shows the message and an error icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ErrorBanner(message: 'Card declined'))),
    );
    expect(find.text('Card declined'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
