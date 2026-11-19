import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/models/payment_model.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';
import 'package:mini_foodpanda/services/notification_service.dart';
import 'package:mini_foodpanda/services/order_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderService service;
  late NotificationService notifications;

  const restaurant = Restaurant(
    id: 'rest-1',
    name: 'Karahi House',
    category: 'Pakistani',
    imageAsset: '',
    rating: 4.5,
    etaMinutes: 30,
    lat: 30.05,
    lng: 72.35,
  );
  const menuItem = MenuItem(id: 'm1', restaurantId: 'rest-1', name: 'Karahi', description: '', price: 900);
  final items = [const CartItem(menuItem: menuItem, quantity: 2)];

  setUp(() {
    firestore = FakeFirebaseFirestore();
    notifications = NotificationService(firestore: firestore);
    service = OrderService(firestore: firestore, notifications: notifications);
  });

  group('placeOrder', () {
    test('computes the total from the cart and falls back to an offset delivery point', () async {
      final order = await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      expect(order.total, 1800);
      expect(order.status, OrderStatus.pending);
      expect(order.deliveryLat, restaurant.lat + 0.01);
      expect(order.deliveryLng, restaurant.lng + 0.01);

      final stored = await firestore.collection('orders').doc(order.id).get();
      expect(stored.exists, true);
    });

    test('uses the given GPS delivery point when provided', () async {
      final order = await service.placeOrder(
        customerId: 'cust-1',
        restaurant: restaurant,
        items: items,
        deliveryLat: 30.1,
        deliveryLng: 72.4,
      );
      expect(order.deliveryLat, 30.1);
      expect(order.deliveryLng, 72.4);
    });
  });

  group('updateStatus', () {
    test('updates the order and sends a matching customer notification', () async {
      final order = await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      await service.updateStatus(order.id, OrderStatus.preparing);

      final updated = await service.watchOrder(order.id).first;
      expect(updated!.status, OrderStatus.preparing);

      final notes = await notifications.watchFor('cust-1').first;
      expect(notes, hasLength(1));
      expect(notes.first.title, 'Order confirmed');
    });

    test('does not notify on a pending status (there is nothing to tell the customer yet)', () async {
      final order = await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      await service.updateStatus(order.id, OrderStatus.pending);
      final notes = await notifications.watchFor('cust-1').first;
      expect(notes, isEmpty);
    });
  });

  group('disputes and refunds', () {
    test('openDispute marks the order and resolveDispute(refund: true) refunds a paid order', () async {
      final placed = await service.placeOrder(
        customerId: 'cust-1',
        restaurant: restaurant,
        items: items,
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.succeeded,
      );
      await service.openDispute(placed.id, 'Food arrived cold');
      var order = await service.watchOrder(placed.id).first;
      expect(order!.disputeStatus, DisputeStatus.open);
      expect(order.disputeReason, 'Food arrived cold');

      await service.resolveDispute(orderId: placed.id, refund: true);
      order = await service.watchOrder(placed.id).first;
      expect(order!.disputeStatus, DisputeStatus.resolved);
      expect(order.paymentStatus, PaymentStatus.refunded);

      final notes = await notifications.watchFor('cust-1').first;
      expect(notes.any((n) => n.title == 'Dispute resolved'), true);
    });

    test('resolveDispute(refund: false) rejects without touching payment status', () async {
      final placed = await service.placeOrder(
        customerId: 'cust-1',
        restaurant: restaurant,
        items: items,
        paymentStatus: PaymentStatus.succeeded,
      );
      await service.openDispute(placed.id, 'Wrong item');
      await service.resolveDispute(orderId: placed.id, refund: false);
      final order = await service.watchOrder(placed.id).first;
      expect(order!.disputeStatus, DisputeStatus.rejected);
      expect(order.paymentStatus, PaymentStatus.succeeded);
    });

    test('refund() sets paymentStatus to refunded and notifies the customer', () async {
      final placed = await service.placeOrder(
        customerId: 'cust-1',
        restaurant: restaurant,
        items: items,
        paymentStatus: PaymentStatus.succeeded,
      );
      await service.refund(placed.id);
      final order = await service.watchOrder(placed.id).first;
      expect(order!.paymentStatus, PaymentStatus.refunded);

      final notes = await notifications.watchFor('cust-1').first;
      expect(notes.any((n) => n.title == 'Refund issued'), true);
    });
  });

  group('watchCustomerOrders / watchAllOrders', () {
    test('watchCustomerOrders only returns that customer\'s orders, newest first', () async {
      final first = await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      await service.placeOrder(customerId: 'cust-2', restaurant: restaurant, items: items);

      final list = await service.watchCustomerOrders('cust-1').first;
      expect(list.map((o) => o.id).toList(), [second.id, first.id]);
    });

    test('watchAllOrders returns every order regardless of customer', () async {
      await service.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
      await service.placeOrder(customerId: 'cust-2', restaurant: restaurant, items: items);
      final list = await service.watchAllOrders().first;
      expect(list.length, 2);
    });
  });
}
