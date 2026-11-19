import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_palette.dart';
import '../models/menu_item_model.dart';
import 'food_thumb.dart';
import 'tap_bounce.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final int quantityInCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Opens the dish details when the photo / text area is tapped.
  final VoidCallback? onTap;

  const MenuItemTile({
    super.key,
    required this.item,
    required this.quantityInCart,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inCart = quantityInCart > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: inCart ? p.red.withValues(alpha: 0.5) : p.line),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: MouseRegion(
                cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FoodThumb(imageUrl: item.imageUrl, name: item.name, category: item.category),
                      const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(context).textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.description,
                        style: TextStyle(color: p.inkSoft, fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Text('Rs. ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.redDeep, fontSize: 15)),
                ],
              ),
            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Stepper(
              name: item.name,
              quantity: quantityInCart,
              onAdd: () {
                HapticFeedback.selectionClick();
                onAdd();
              },
              onRemove: () {
                HapticFeedback.selectionClick();
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String name;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _Stepper({required this.name, required this.quantity, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: quantity == 0
          ? Semantics(
              key: const ValueKey('add'),
              button: true,
              label: 'Add $name to cart',
              child: TapBounce(
                onTap: onAdd,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [p.redBright, p.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: p.onRed, size: 24),
                ),
              ),
            )
          : Container(
              key: const ValueKey('stepper'),
              decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Remove one $name',
                    child: TapBounce(
                      onTap: onRemove,
                      // 13 + 18 + 13 = 44dp touch target.
                      child: Padding(
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
                      child: Text('$quantity',
                          key: ValueKey(quantity),
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
    );
  }
}
