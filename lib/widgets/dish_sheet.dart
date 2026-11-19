import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_palette.dart';
import '../models/menu_item_model.dart';
import '../providers/cart_provider.dart';
import 'custom_button.dart';
import 'food_thumb.dart';

/// Bottom sheet with a dish's large photo, full description and a live
/// quantity control (it follows the cart, so it stays correct if the cart
/// changes while the sheet is open).
Future<void> showDishSheet(
  BuildContext context, {
  required MenuItem item,
  required VoidCallback onAdd,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DishSheet(item: item, onAdd: onAdd, onRemove: onRemove),
  );
}

class _DishSheet extends ConsumerWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _DishSheet({required this.item, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final qty = ref
        .watch(cartProvider)
        .where((c) => c.menuItem.id == item.id)
        .fold<int>(0, (n, c) => n + c.quantity);
    final price = 'Rs. ${item.price.toStringAsFixed(0)}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, c) => FoodThumb(
                  imageUrl: item.imageUrl,
                  name: item.name,
                  category: item.category,
                  size: math.min(c.maxWidth, 340),
                  radius: 22,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(item.name, style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(width: 12),
                Text(price, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.redDeep)),
              ],
            ),
            if (item.category.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(99)),
                  child: Text(item.category,
                      style: TextStyle(color: p.redDeep, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.description, style: TextStyle(color: p.inkSoft, fontSize: 15, height: 1.45)),
            ],
            const SizedBox(height: 20),
            if (qty == 0)
              CustomButton(label: 'Add to cart · $price', icon: Icons.add_shopping_cart_rounded, onPressed: onAdd)
            else
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Remove one',
                          icon: Icon(Icons.remove_rounded, color: p.redDeep),
                          onPressed: onRemove,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: SizedBox(
                            key: ValueKey(qty),
                            width: 28,
                            child: Text('$qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.redDeep)),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add one',
                          icon: Icon(Icons.add_rounded, color: p.redDeep),
                          onPressed: onAdd,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(label: 'Done', onPressed: () => Navigator.pop(context))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
