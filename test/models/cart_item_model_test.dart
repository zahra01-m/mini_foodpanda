import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';

void main() {
  const item = MenuItem(
    id: 'item-1',
    restaurantId: 'rest-1',
    name: 'Chicken Karahi',
    description: 'Half kg',
    price: 950,
  );

  group('CartItem', () {
    test('subtotal multiplies price by quantity', () {
      const cartItem = CartItem(menuItem: item, quantity: 3);
      expect(cartItem.subtotal, 2850);
    });

    test('copyWith changes only quantity', () {
      const cartItem = CartItem(menuItem: item, quantity: 1);
      final updated = cartItem.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.menuItem, item);
    });

    test('toMap/fromMap round-trips the ordered-item snapshot', () {
      const cartItem = CartItem(menuItem: item, quantity: 2);
      final map = cartItem.toMap();
      expect(map, {
        'menuItemId': 'item-1',
        'restaurantId': 'rest-1',
        'name': 'Chicken Karahi',
        'description': 'Half kg',
        'price': 950.0,
        'quantity': 2,
      });

      final restored = CartItem.fromMap(map);
      expect(restored.menuItem.id, item.id);
      expect(restored.menuItem.name, item.name);
      expect(restored.menuItem.price, item.price);
      expect(restored.quantity, 2);
      // available isn't part of the order snapshot — defaults true.
      expect(restored.menuItem.available, true);
    });

    test('fromMap fills in sane defaults for missing fields', () {
      final restored = CartItem.fromMap(const {});
      expect(restored.menuItem.id, '');
      expect(restored.menuItem.price, 0);
      expect(restored.quantity, 1);
    });
  });
}
