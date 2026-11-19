import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/services/notification_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = NotificationService(firestore: firestore);
  });

  FoodOrder orderWith(OrderStatus status) => FoodOrder(
        id: 'o1',
        customerId: 'cust-1',
        restaurantId: 'r1',
        restaurantName: 'Karahi House',
        items: const <CartItem>[],
        total: 500,
        status: status,
        createdAt: DateTime(2026),
      );

  group('notifyUser / watchFor', () {
    test('a notification is written for that user and shows up unread', () async {
      await service.notifyUser(userId: 'cust-1', title: 'Hi', body: 'Body text');
      final list = await service.watchFor('cust-1').first;
      expect(list, hasLength(1));
      expect(list.first.title, 'Hi');
      expect(list.first.read, false);
    });

    test('watchFor never returns another user\'s notifications', () async {
      await service.notifyUser(userId: 'cust-1', title: 'For 1', body: '');
      await service.notifyUser(userId: 'cust-2', title: 'For 2', body: '');
      final list = await service.watchFor('cust-1').first;
      expect(list.map((n) => n.title), ['For 1']);
    });
  });

  group('notifyOrderStatus', () {
    test('sends a status-specific message for preparing/outForDelivery/delivered/cancelled', () async {
      for (final status in [
        OrderStatus.preparing,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]) {
        await service.notifyOrderStatus(orderWith(status));
      }
      final list = await service.watchFor('cust-1').first;
      expect(list.length, 4);
      expect(list.map((n) => n.title).toSet(), {
        'Order confirmed',
        'On the way',
        'Delivered',
        'Order cancelled',
      });
    });

    test('sends nothing for a pending order', () async {
      await service.notifyOrderStatus(orderWith(OrderStatus.pending));
      final list = await service.watchFor('cust-1').first;
      expect(list, isEmpty);
    });
  });

  group('markAllRead', () {
    test('marks only the given user\'s unread notifications as read', () async {
      await service.notifyUser(userId: 'cust-1', title: 'A', body: '');
      await service.notifyUser(userId: 'cust-1', title: 'B', body: '');
      await service.notifyUser(userId: 'cust-2', title: 'C', body: '');

      await service.markAllRead('cust-1');

      final mine = await service.watchFor('cust-1').first;
      expect(mine.every((n) => n.read), true);

      final other = await service.watchFor('cust-2').first;
      expect(other.single.read, false);
    });
  });
}
