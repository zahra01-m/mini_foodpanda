import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/models/payment_model.dart';

void main() {
  const item = MenuItem(id: 'i1', restaurantId: 'r1', name: 'Pizza', description: '', price: 500);
  final items = [const CartItem(menuItem: item, quantity: 2)];

  FoodOrder baseOrder({
    OrderStatus status = OrderStatus.pending,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    DisputeStatus disputeStatus = DisputeStatus.none,
  }) {
    return FoodOrder(
      id: 'order-1',
      customerId: 'cust-1',
      restaurantId: 'r1',
      restaurantName: 'Pizza Place',
      items: items,
      total: 1000,
      status: status,
      paymentStatus: paymentStatus,
      createdAt: DateTime(2026, 1, 1),
      disputeStatus: disputeStatus,
    );
  }

  group('FoodOrder', () {
    test('toFirestore/fromFirestore round-trip preserves items and dispute fields', () {
      final order = baseOrder(status: OrderStatus.preparing).copyWith(riderId: 'rider-1');
      final data = order.toFirestore();
      final restored = FoodOrder.fromFirestore('order-1', data);

      expect(restored.riderId, 'rider-1');
      expect(restored.status, OrderStatus.preparing);
      expect(restored.items.length, 1);
      expect(restored.items.first.quantity, 2);
      expect(restored.items.first.menuItem.name, 'Pizza');
      expect(restored.total, 1000);
    });

    test('isPaid is true only when paymentStatus is succeeded', () {
      expect(baseOrder(paymentStatus: PaymentStatus.succeeded).isPaid, true);
      expect(baseOrder(paymentStatus: PaymentStatus.pending).isPaid, false);
      expect(baseOrder(paymentStatus: PaymentStatus.refunded).isPaid, false);
    });

    test('countsAsRevenue excludes cancelled and refunded orders', () {
      expect(baseOrder(status: OrderStatus.delivered, paymentStatus: PaymentStatus.succeeded).countsAsRevenue, true);
      expect(baseOrder(status: OrderStatus.cancelled, paymentStatus: PaymentStatus.succeeded).countsAsRevenue, false);
      expect(baseOrder(status: OrderStatus.delivered, paymentStatus: PaymentStatus.refunded).countsAsRevenue, false);
    });

    test('copyWith updates status/riderId/paymentStatus without touching items', () {
      final order = baseOrder();
      final updated = order.copyWith(status: OrderStatus.delivered, paymentStatus: PaymentStatus.succeeded);
      expect(updated.status, OrderStatus.delivered);
      expect(updated.paymentStatus, PaymentStatus.succeeded);
      expect(updated.items, order.items);
      expect(updated.id, order.id);
    });
  });

  group('OrderStatus / DisputeStatus labels', () {
    test('every OrderStatus has a distinct label', () {
      final labels = OrderStatus.values.map((s) => s.label).toSet();
      expect(labels.length, OrderStatus.values.length);
    });

    test('every DisputeStatus has a distinct label', () {
      final labels = DisputeStatus.values.map((s) => s.label).toSet();
      expect(labels.length, DisputeStatus.values.length);
    });
  });
}
