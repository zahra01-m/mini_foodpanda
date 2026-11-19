import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/services/demo_data_service.dart';
import 'package:mini_foodpanda/services/mock_data_service.dart';

void main() {
  final now = DateTime(2026, 11, 18, 12);

  test('every sample order references real sample restaurants, items and people', () {
    final restaurantIds = MockDataService.restaurants.map((r) => r.id).toSet();
    final customerIds = DemoDataService.customers.map((u) => u.id).toSet();
    final riderIds = DemoDataService.riders.map((u) => u.id).toSet();
    final orders = DemoDataService.buildOrders(now: now);
    expect(orders, isNotEmpty);
    for (final o in orders) {
      expect(restaurantIds.contains(o.restaurantId), isTrue, reason: o.id);
      expect(customerIds.contains(o.customerId), isTrue, reason: o.id);
      if (o.riderId != null) expect(riderIds.contains(o.riderId), isTrue, reason: o.id);
      expect(o.items, isNotEmpty);
      expect(o.total, greaterThan(0));
      // Orders that are being delivered must have a rider.
      if (o.status == OrderStatus.outForDelivery) expect(o.riderId, isNotNull);
    }
    expect(orders.map((o) => o.id).toSet().length, orders.length, reason: 'duplicate order ids');
  });

  test('sample data covers every order status', () {
    final statuses = DemoDataService.buildOrders(now: now).map((o) => o.status).toSet();
    expect(statuses, containsAll(OrderStatus.values));
  });

  test('seedAll writes people, orders, reviews and is idempotent', () async {
    final firestore = FakeFirebaseFirestore();
    final service = DemoDataService(firestore: firestore);

    final result = await service.seedAll(now: now);
    expect((await firestore.collection('users').get()).docs.length,
        DemoDataService.customers.length + DemoDataService.riders.length);
    expect((await firestore.collection('orders').get()).docs.length, result.orders);
    expect((await firestore.collection('reviews').get()).docs.length, result.reviews);
    expect((await firestore.collection('riderLocations').get()).docs, isNotEmpty);
    expect((await firestore.collection('notifications').get()).docs, isNotEmpty);

    await service.seedAll(now: now);
    expect((await firestore.collection('orders').get()).docs.length, result.orders);
    expect((await firestore.collection('users').get()).docs.length,
        DemoDataService.customers.length + DemoDataService.riders.length);
  });

  test('every order item belongs to the restaurant it was ordered from', () {
    for (final o in DemoDataService.buildOrders(now: now)) {
      for (final line in o.items) {
        expect(line.menuItem.restaurantId, o.restaurantId, reason: '${o.id}: ${line.menuItem.name}');
      }
    }
  });

  test('seedAll deletes sample orders left over from retired restaurants', () async {
    final firestore = FakeFirebaseFirestore();
    final stale = DemoDataService.retiredOrderIds.first;
    await firestore.collection('orders').doc(stale).set({'restaurantId': 'sample-karachi-biryani'});
    await firestore.collection('reviews').doc(stale).set({'rating': 4});
    await firestore.collection('notifications').doc('sample-notif-$stale').set({'userId': 'x'});

    await DemoDataService(firestore: firestore).seedAll(now: now);

    expect((await firestore.collection('orders').doc(stale).get()).exists, isFalse);
    expect((await firestore.collection('reviews').doc(stale).get()).exists, isFalse);
    expect((await firestore.collection('notifications').doc('sample-notif-$stale').get()).exists, isFalse);
  });
}
