import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/pricing.dart';
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
  const item = MenuItem(id: 'm1', restaurantId: 'rest-1', name: 'Karahi', description: '', price: 1000);
  final items = [const CartItem(menuItem: item, quantity: 1)];

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = OrderService(firestore: firestore, notifications: NotificationService(firestore: firestore));
  });

  test('a valid code lowers the stored total and is recorded on the order', () async {
    final plain = Pricing.of(1000);
    final order = await service.placeOrder(
      customerId: 'c1',
      restaurant: restaurant,
      items: items,
      promoCode: 'welcome10',
    );
    expect(order.discount, 100);
    expect(order.promoCode, 'WELCOME10');
    expect(order.total, plain.total - 100);

    final stored = (await firestore.collection('orders').doc(order.id).get()).data()!;
    expect(stored['discount'], 100);
    expect(stored['promoCode'], 'WELCOME10');
  });

  test('an unknown code is ignored: no discount and no code stored', () async {
    final order = await service.placeOrder(
      customerId: 'c1',
      restaurant: restaurant,
      items: items,
      promoCode: 'MADEUP',
    );
    expect(order.discount, 0);
    expect(order.promoCode, '');
    expect(order.total, Pricing.of(1000).total);
  });
}
