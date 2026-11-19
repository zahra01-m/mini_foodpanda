import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/widgets/empty_state.dart';

void main() {
  testWidgets('shows icon, title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.inbox_outlined, title: 'Nothing here', subtitle: 'Come back later'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Come back later'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('shows a retry button only when onRetry is provided, and it fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.error_outline,
            title: 'Failed',
            subtitle: 'Something went wrong',
            retryLabel: 'Retry now',
            onRetry: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry now'), findsOneWidget);
    await tester.tap(find.text('Retry now'));
    await tester.pump();
    expect(tapped, true);
  });
}
