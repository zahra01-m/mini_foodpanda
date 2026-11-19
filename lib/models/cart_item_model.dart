import '../core/utils/firestore_utils.dart';
import 'menu_item_model.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  double get subtotal => menuItem.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(menuItem: menuItem, quantity: quantity ?? this.quantity);
  }

  /// Snapshot stored inside `orders/{id}.items[]` — a copy of the item as
  /// it was ordered, so later menu edits never rewrite order history.
  Map<String, dynamic> toMap() => {
        'menuItemId': menuItem.id,
        'restaurantId': menuItem.restaurantId,
        'name': menuItem.name,
        'description': menuItem.description,
        'price': menuItem.price,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) {
    return CartItem(
      menuItem: MenuItem(
        id: (m['menuItemId'] as String?) ?? '',
        restaurantId: (m['restaurantId'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        price: readDouble(m['price']),
      ),
      quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
