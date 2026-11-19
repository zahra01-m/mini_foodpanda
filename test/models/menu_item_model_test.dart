import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';

void main() {
  group('MenuItem', () {
    test('toFirestore/fromFirestore round-trip', () {
      const item = MenuItem(
        id: 'item-1',
        restaurantId: 'rest-1',
        name: 'Pizza',
        description: '12 inch',
        price: 850,
        available: false,
      );
      final data = item.toFirestore();
      final restored = MenuItem.fromFirestore('item-1', data);
      expect(restored.restaurantId, 'rest-1');
      expect(restored.name, 'Pizza');
      expect(restored.description, '12 inch');
      expect(restored.price, 850);
      expect(restored.available, false);
    });

    test('fromFirestore defaults available to true when missing', () {
      final restored = MenuItem.fromFirestore('item-2', {
        'restaurantId': 'rest-1',
        'name': 'Fries',
        'description': '',
        'price': 300,
      });
      expect(restored.available, true);
    });

    test('copyWith only changes given fields', () {
      const item = MenuItem(id: 'i1', restaurantId: 'r1', name: 'A', description: 'd', price: 100);
      final updated = item.copyWith(price: 150, available: false);
      expect(updated.id, 'i1');
      expect(updated.name, 'A');
      expect(updated.price, 150);
      expect(updated.available, false);
    });
  });
}
