import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/image_data.dart';
import '../core/utils/pricing.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

/// The shopping cart. It is saved to the device after every change and
/// restored on the next launch (carts older than [_maxAge] are dropped).
/// Because a restored cart can be stale, [syncWithMenu] re-checks it
/// against the restaurant's live menu when the cart screen opens.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _restore();
  }

  static const _prefsKey = 'cart_v1';
  static const _maxAge = Duration(hours: 12);

  // --- persistence -------------------------------------------------------

  // Every assignment to `state` is saved, so no mutator needs to remember to.
  @override
  List<CartItem> get state => super.state;

  @override
  set state(List<CartItem> value) {
    super.state = value;
    _persist(value);
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse((map['savedAt'] as String?) ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > _maxAge) {
        await prefs.remove(_prefsKey);
        return;
      }
      final lines = (map['lines'] as List)
          .map((e) => _lineFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Don't clobber anything the user already added while this was loading.
      if (mounted && super.state.isEmpty && lines.isNotEmpty) super.state = lines;
    } catch (_) {
      // Unreadable saved cart: start empty rather than crash.
    }
  }

  Future<void> _persist(List<CartItem> lines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (lines.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }
      await prefs.setString(
        _prefsKey,
        jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'lines': lines.map(_lineToJson).toList()}),
      );
    } catch (_) {}
  }

  static Map<String, dynamic> _lineToJson(CartItem c) => {
        'id': c.menuItem.id,
        'restaurantId': c.menuItem.restaurantId,
        'name': c.menuItem.name,
        'description': c.menuItem.description,
        'price': c.menuItem.price,
        'category': c.menuItem.category,
        // Uploaded photos are big data URIs; the live menu refills them on sync.
        'imageUrl': isDataImage(c.menuItem.imageUrl) ? '' : c.menuItem.imageUrl,
        'quantity': c.quantity,
      };

  static CartItem _lineFromJson(Map<String, dynamic> m) => CartItem(
        menuItem: MenuItem(
          id: m['id'] as String,
          restaurantId: (m['restaurantId'] as String?) ?? '',
          name: (m['name'] as String?) ?? '',
          description: (m['description'] as String?) ?? '',
          price: (m['price'] as num).toDouble(),
          category: (m['category'] as String?) ?? '',
          imageUrl: (m['imageUrl'] as String?) ?? '',
        ),
        quantity: (m['quantity'] as num).toInt(),
      );

  /// Drops dishes that are gone or sold out and refreshes prices from the
  /// live [menu]. Returns how many lines were removed / repriced.
  ({int removed, int repriced}) syncWithMenu(List<MenuItem> menu) {
    final byId = {for (final m in menu) m.id: m};
    var removed = 0;
    var repriced = 0;
    var photoRefilled = false;
    final next = <CartItem>[];
    for (final line in state) {
      final current = byId[line.menuItem.id];
      if (current == null || !current.available) {
        removed++;
        continue;
      }
      if (current.price != line.menuItem.price) repriced++;
      // A restored cart drops uploaded photos (see _lineToJson); put them back.
      if (line.menuItem.imageUrl.isEmpty && current.imageUrl.isNotEmpty) photoRefilled = true;
      next.add(CartItem(menuItem: current, quantity: line.quantity));
    }
    if (removed > 0 || repriced > 0 || photoRefilled) state = next;
    return (removed: removed, repriced: repriced);
  }

  // --- cart operations ---------------------------------------------------

  /// Restaurant the cart currently belongs to (null when empty).
  String? get restaurantId => state.isEmpty ? null : state.first.menuItem.restaurantId;

  /// True when [item] is from a different restaurant than what's already
  /// in the cart. Checkout only supports one restaurant per order, so the
  /// UI should ask before calling [replaceWith].
  bool conflictsWith(MenuItem item) => state.isNotEmpty && restaurantId != item.restaurantId;

  /// Empty the cart and start a new one with [item].
  void replaceWith(MenuItem item) => state = [CartItem(menuItem: item, quantity: 1)];

  /// Replace the whole cart (used by "Order again").
  void setLines(List<CartItem> lines) => state = List.of(lines);

  void add(MenuItem item) {
    final idx = state.indexWhere((c) => c.menuItem.id == item.id);
    if (idx == -1) {
      state = [...state, CartItem(menuItem: item, quantity: 1)];
    } else {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
      state = updated;
    }
  }

  void decrement(MenuItem item) {
    final idx = state.indexWhere((c) => c.menuItem.id == item.id);
    if (idx == -1) return;
    final current = state[idx];
    if (current.quantity <= 1) {
      state = [...state]..removeAt(idx);
    } else {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity - 1);
      state = updated;
    }
  }

  /// Remove a line entirely regardless of quantity (swipe-to-delete).
  void removeLine(MenuItem item) => state = state.where((c) => c.menuItem.id != item.id).toList();

  /// Put a removed line back (used by the Undo snackbar).
  void restoreLine(CartItem line) => state = [...state, line];

  void clear() => state = [];

  /// Food subtotal (before delivery and service fees).
  double get total => state.fold(0, (sum, c) => sum + c.subtotal);

  /// Subtotal + delivery fee + service fee.
  PriceBreakdown get breakdown => Pricing.of(total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
