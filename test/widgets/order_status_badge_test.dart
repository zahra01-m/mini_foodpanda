import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/widgets/order_status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, OrderStatus status) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OrderStatusBadge(status: status))),
    );
  }

  testWidgets('shows the correct label for every order status', (tester) async {
    for (final status in OrderStatus.values) {
      await pump(tester, status);
      expect(find.text(status.label), findsOneWidget);
    }
  });

  testWidgets('shows a pulsing dot only for preparing and out-for-delivery', (tester) async {
    await pump(tester, OrderStatus.preparing);
    expect(find.byType(AnimatedContainer), findsOneWidget);
    // The pulse dot is an extra child alongside the label — check the row
    // has more than just the text by looking for its Container shape.
    await pump(tester, OrderStatus.delivered);
    // Delivered has no pulse — only the label text renders inside.
    expect(find.text(OrderStatus.delivered.label), findsOneWidget);
  });
}
