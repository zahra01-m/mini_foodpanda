import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../screens/customer/cart_screen.dart';
import '../../widgets/food_loader.dart';

/// "Order again": rebuilds the cart from a past order using the
/// restaurant's *current* menu, so removed or sold-out dishes are skipped
/// and today's prices are used. Tells the customer about anything that
/// changed, then opens the cart.
Future<void> reorder(BuildContext context, WidgetRef ref, FoodOrder order) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // Food-themed busy dialog while we look up the live menu.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: FoodLoader(message: 'Checking today\'s menu…', size: 52),
        ),
      ),
    ),
  );

  List<CartItem> lines = [];
  var skipped = 0;
  var repriced = false;
  var restaurantOpen = true;
  try {
    final open = await ref.read(restaurantListProvider.future);
    restaurantOpen = open.any((r) => r.id == order.restaurantId);
    if (restaurantOpen) {
      final menu = await ref
          .read(restaurantServiceProvider)
          .watchMenu(order.restaurantId)
          .first
          .timeout(const Duration(seconds: 10));
      for (final old in order.items) {
        final match = menu.where((m) => m.id == old.menuItem.id && m.available);
        if (match.isEmpty) {
          skipped++;
          continue;
        }
        final current = match.first;
        if (current.price != old.menuItem.price) repriced = true;
        lines.add(CartItem(menuItem: current, quantity: old.quantity));
      }
    }
  } catch (_) {
    if (navigator.mounted) navigator.pop(); // close dialog
    messenger.showSnackBar(const SnackBar(content: Text('Couldn\'t check the menu. Please try again.')));
    return;
  }
  if (navigator.mounted) navigator.pop(); // close dialog

  if (!restaurantOpen) {
    messenger.showSnackBar(SnackBar(content: Text('${order.restaurantName} isn\'t available right now.')));
    return;
  }
  if (lines.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('None of those dishes are available right now.')));
    return;
  }
  if (!context.mounted) return;

  final cart = ref.read(cartProvider.notifier);
  if (ref.read(cartProvider).isNotEmpty) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace your cart?'),
        content: const Text('Your cart already has items. Ordering again will replace them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep my cart')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
        ],
      ),
    );
    if (replace != true) return;
  }

  cart.setLines(lines);
  if (skipped > 0 || repriced) {
    final parts = <String>[
      if (skipped > 0) '$skipped item${skipped == 1 ? '' : 's'} unavailable',
      if (repriced) 'prices updated',
    ];
    messenger.showSnackBar(SnackBar(content: Text('Cart ready — ${parts.join(', ')}.')));
  }
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
}
