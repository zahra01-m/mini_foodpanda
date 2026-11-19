import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';
import 'package:mini_foodpanda/services/notification_service.dart';
import 'package:mini_foodpanda/services/order_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderService service;

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
  const item = MenuItem(id: 'm1', restaurantId: 'rest-1', name: 'Karahi', description: '', price: 900);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = OrderService(firestore: firestore, notifications: NotificationService(firestore: firestore));
  });

  test('a pending order can be cancelled by the customer', () async {
    final order = await service.placeOrder(
      customerId: 'cust-1',
      restaurant: restaurant,
      items: [const CartItem(menuItem: item, quantity: 1)],
    );
    await service.cancelOrder(order.id);
    final stored = await firestore.collection('orders').doc(order.id).get();
    expect(stored.data()!['status'], 'cancelled');
  });

  test('an order the restaurant already started cannot be cancelled', () async {
    final order = await service.placeOrder(
      customerId: 'cust-1',
      restaurant: restaurant,
      items: [const CartItem(menuItem: item, quantity: 1)],
    );
    await firestore.collection('orders').doc(order.id).update({'status': 'preparing'});
    expect(() => service.cancelOrder(order.id), throwsStateError);
    final stored = await firestore.collection('orders').doc(order.id).get();
    expect(stored.data()!['status'], 'preparing');
  });
}
