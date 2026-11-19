import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/pricing.dart';
import '../../models/cart_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/price_breakdown.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // A cart restored from a previous session (or left open for a while)
    // may hold dishes that are sold out or repriced — check once on open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWithLiveMenu());
  }

  Future<void> _syncWithLiveMenu() async {
    final restaurantId = ref.read(cartProvider.notifier).restaurantId;
    if (restaurantId == null) return;
    try {
      final menu = await ref
          .read(restaurantServiceProvider)
          .watchMenu(restaurantId)
          .first
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final r = ref.read(cartProvider.notifier).syncWithMenu(menu);
      if (r.removed > 0 || r.repriced > 0) {
        final parts = <String>[
          if (r.removed > 0) '${r.removed} item${r.removed == 1 ? '' : 's'} no longer available',
          if (r.repriced > 0) 'prices updated',
        ];
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Your cart was updated: ${parts.join(', ')}.')));
      }
    } catch (_) {
      // Offline or slow: keep the cart as is; checkout still works.
    }
  }

  Future<void> _confirmClear(CartNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This removes every item from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) notifier.clear();
  }

  Widget _buildList(List<CartItem> cart, CartNotifier notifier) {
    final p = context.palette;
    return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final line = cart[i];
                return Dismissible(
                  key: ValueKey(line.menuItem.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: p.redTint,
                    child: Icon(Icons.delete_outline_rounded, color: p.danger),
                  ),
                  onDismissed: (_) {
                    notifier.removeLine(line.menuItem);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${line.menuItem.name} removed'),
                          action: SnackBarAction(label: 'Undo', onPressed: () => notifier.restoreLine(line)),
                        ),
                      );
                  },
                  child: FadeSlideIn(
                    index: i < 8 ? i : 0,
                    baseDelay: const Duration(milliseconds: 50),
                    child: CartItemTile(
                      cartItem: line,
                      onAdd: () => notifier.add(line.menuItem),
                      onRemove: () => notifier.decrement(line.menuItem),
                    ),
                  ),
                );
              },
            );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final p = context.palette;
    final price = Pricing.of(notifier.total);
    String? restaurantName;
    final rid = notifier.restaurantId;
    for (final r in ref.watch(restaurantListProvider).valueOrNull ?? const <Restaurant>[]) {
      if (r.id == rid) restaurantName = r.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear cart',
              onPressed: () => _confirmClear(notifier),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
              subtitle: 'Add items from a restaurant to get started',
              retryLabel: 'Browse restaurants',
              retryIcon: Icons.storefront_rounded,
              onRetry: () => Navigator.pop(context),
            )
          : Column(
              children: [
                // Lives above the list (not in the sticky bottom bar) so the
                // bottom bar stays compact and the items keep their room.
                if (restaurantName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 18, color: p.redDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Ordering from $restaurantName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: FreeDeliveryBar(subtotal: price.subtotal),
                ),
                Expanded(child: _buildList(cart, notifier)),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.card,
                  boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceBreakdownView.from(price),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: price.meetsMinimum
                            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()))
                            : null,
                        child: Text(price.meetsMinimum
                            ? 'Proceed to checkout'
                            : 'Add Rs. ${price.amountToMinimum.toStringAsFixed(0)} more to order (minimum Rs. ${Pricing.minimumOrder.toStringAsFixed(0)})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
