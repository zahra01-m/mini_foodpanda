import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import '../models/cart_item_model.dart';
import 'food_thumb.dart';
import 'tap_bounce.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = cartItem.menuItem.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          FoodThumb(
            imageUrl: cartItem.menuItem.imageUrl,
            name: name,
            category: cartItem.menuItem.category,
            size: 48,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('Rs. ${cartItem.menuItem.price.toStringAsFixed(0)} each',
                    style: TextStyle(color: p.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Remove one $name',
                  child: TapBounce(
                    onTap: onRemove,
                    child: Padding(
                      // 13 + 18 + 13 = 44dp touch target.
                      padding: const EdgeInsets.all(13),
                      child: Icon(Icons.remove_rounded, size: 18, color: p.redDeep),
                    ),
                  ),
                ),
                SizedBox(
                  width: 22,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text('${cartItem.quantity}',
                        key: ValueKey(cartItem.quantity),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800, color: p.redDeep)),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Add one $name',
                  child: TapBounce(
                    onTap: onAdd,
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Icon(Icons.add_rounded, size: 18, color: p.redDeep),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            // Slides up/down as the line total changes.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text('Rs. ${cartItem.subtotal.toStringAsFixed(0)}',
                  key: ValueKey(cartItem.subtotal),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.redDeep)),
            ),
          ),
        ],
      ),
    );
  }
}
