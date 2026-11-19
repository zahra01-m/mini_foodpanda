import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/providers/cart_provider.dart';

void main() {
  const pizza = MenuItem(id: 'pizza', restaurantId: 'r1', name: 'Pizza', description: '', price: 500);
  const fries = MenuItem(id: 'fries', restaurantId: 'r1', name: 'Fries', description: '', price: 300);

  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('CartNotifier', () {
    test('adding a new item inserts it with quantity 1', () {
      container.read(cartProvider.notifier).add(pizza);
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 1);
    });

    test('adding the same item again increments its quantity instead of duplicating', () {
      final notifier = container.read(cartProvider.notifier)
        ..add(pizza)
        ..add(pizza);
      final cart = notifier.state;
      expect(cart.length, 1);
      expect(cart.first.quantity, 2);
    });

    test('decrement reduces quantity, and removes the line at zero', () {
      final notifier = container.read(cartProvider.notifier)
        ..add(pizza)
        ..add(pizza);
      notifier.decrement(pizza);
      expect(notifier.state.first.quantity, 1);
      notifier.decrement(pizza);
      expect(notifier.state, isEmpty);
    });

    test('decrement on an item not in the cart is a no-op', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.decrement(pizza);
      expect(notifier.state, isEmpty);
    });

    test('clear empties the cart', () {
      final notifier = container.read(cartProvider.notifier)
        ..add(pizza)
        ..add(fries);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });

    test('total sums subtotals across distinct items', () {
      final notifier = container.read(cartProvider.notifier)
        ..add(pizza)
        ..add(pizza)
        ..add(fries);
      // 2 x 500 + 1 x 300
      expect(notifier.total, 1300);
    });
  });
}
