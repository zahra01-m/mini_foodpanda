import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';
import 'package:mini_foodpanda/services/order_service.dart';
import 'package:mini_foodpanda/services/rider_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderService orderService;
  late RiderService riderService;

  const restaurant = Restaurant(
    id: 'rest-1', name: 'A', category: 'x', imageAsset: '', rating: 4, etaMinutes: 20,
  );
  const menuItem = MenuItem(id: 'm1', restaurantId: 'rest-1', name: 'Item', description: '', price: 500);
  final items = [const CartItem(menuItem: menuItem, quantity: 1)];

  setUp(() {
    firestore = FakeFirebaseFirestore();
    orderService = OrderService(firestore: firestore);
    riderService = RiderService(firestore: firestore, orders: orderService);
  });

  Future<String> placeAndPrepare() async {
    final order = await orderService.placeOrder(customerId: 'cust-1', restaurant: restaurant, items: items);
    await orderService.updateStatus(order.id, OrderStatus.preparing);
    return order.id;
  }

  group('watchIncomingRequests', () {
    test('only shows unassigned orders that are preparing', () async {
      final preparingId = await placeAndPrepare();
      final pendingOrder = await orderService.placeOrder(customerId: 'cust-2', restaurant: restaurant, items: items);

      final requests = await riderService.watchIncomingRequests().first;
      expect(requests.map((o) => o.id), contains(preparingId));
      expect(requests.map((o) => o.id), isNot(contains(pendingOrder.id)));
    });

    test('an order already claimed by a rider no longer appears', () async {
      final orderId = await placeAndPrepare();
      await riderService.acceptOrder(orderId: orderId, riderId: 'rider-1');
      final requests = await riderService.watchIncomingRequests().first;
      expect(requests, isEmpty);
    });
  });

  group('acceptOrder', () {
    test('the first rider to accept succeeds', () async {
      final orderId = await placeAndPrepare();
      final ok = await riderService.acceptOrder(orderId: orderId, riderId: 'rider-1');
      expect(ok, true);
      final order = await orderService.watchOrder(orderId).first;
      expect(order!.riderId, 'rider-1');
    });

    test('a second rider cannot claim an already-assigned order', () async {
      final orderId = await placeAndPrepare();
      await riderService.acceptOrder(orderId: orderId, riderId: 'rider-1');
      final ok = await riderService.acceptOrder(orderId: orderId, riderId: 'rider-2');
      expect(ok, false);
      final order = await orderService.watchOrder(orderId).first;
      expect(order!.riderId, 'rider-1');
    });

    test('fails for an order that does not exist', () async {
      final ok = await riderService.acceptOrder(orderId: 'nope', riderId: 'rider-1');
      expect(ok, false);
    });
  });

  group('delivery lifecycle', () {
    test('markPickedUp and markDelivered move the order through the rider flow', () async {
      final orderId = await placeAndPrepare();
      await riderService.acceptOrder(orderId: orderId, riderId: 'rider-1');

      var active = await riderService.watchActiveDelivery('rider-1').first;
      expect(active!.status, OrderStatus.preparing);

      await riderService.markPickedUp(orderId);
      active = await riderService.watchActiveDelivery('rider-1').first;
      expect(active!.status, OrderStatus.outForDelivery);

      await riderService.markDelivered(orderId);
      active = await riderService.watchActiveDelivery('rider-1').first;
      expect(active, isNull); // delivered orders are no longer "active"

      final history = await riderService.watchHistory('rider-1').first;
      expect(history.map((o) => o.id), contains(orderId));
    });
  });

  group('earningsOf', () {
    test('applies the commission rate to the total across all history orders', () {
      final history = [
        FoodOrder(
          id: '1', customerId: 'c', restaurantId: 'r', restaurantName: 'R',
          items: const [], total: 1000, status: OrderStatus.delivered, createdAt: DateTime(2026),
        ),
        FoodOrder(
          id: '2', customerId: 'c', restaurantId: 'r', restaurantName: 'R',
          items: const [], total: 500, status: OrderStatus.delivered, createdAt: DateTime(2026),
        ),
      ];
      // Default 12% commission: (1000 + 500) * 0.12
      expect(RiderService.earningsOf(history), closeTo(180, 0.001));
      expect(RiderService.earningsOf(history, commissionRate: 0.5), closeTo(750, 0.001));
    });

    test('is zero for an empty history', () {
      expect(RiderService.earningsOf(const []), 0);
    });
  });
}
