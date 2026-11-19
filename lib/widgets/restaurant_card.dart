import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import '../models/restaurant_model.dart';
import 'restaurant_image.dart';
import 'tap_bounce.dart';

/// Photo-first restaurant card: large image on top with the delivery
/// time and favorite button overlaid, name/category and rating below.
///
/// All colours come from the brightness-aware palette — the previous
/// version kept a cream card in dark mode while the title picked up the
/// (light) dark-theme text colour, leaving restaurant names unreadable.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TapBounce(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(color: p.shadow, blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'restaurant-${restaurant.id}',
                      child: RestaurantImage(restaurant: restaurant),
                    ),
                    PositionedDirectional(
                      start: 10,
                      bottom: 10,
                      child: _Pill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: p.redDeep),
                            const SizedBox(width: 4),
                            Text('${restaurant.etaMinutes} min',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: p.ink)),
                          ],
                        ),
                      ),
                    ),
                    if (onToggleFavorite != null)
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: Semantics(
                          button: true,
                          label: isFavorite
                              ? 'Remove ${restaurant.name} from favorites'
                              : 'Add ${restaurant.name} to favorites',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onToggleFavorite,
                            // 4 + 9 + 18 + 9 + 4 = 44dp touch target.
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: p.card,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: p.shadow, blurRadius: 6)],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(scale: animation, child: child),
                                  child: Icon(
                                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    key: ValueKey(isFavorite),
                                    size: 18,
                                    color: isFavorite ? p.red : p.inkSoft,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant.name,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(restaurant.category,
                              style: TextStyle(color: p.inkSoft, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      label: 'Rated ${restaurant.rating.toStringAsFixed(1)} out of 5',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 15, color: p.gold),
                            const SizedBox(width: 3),
                            Text(restaurant.rating.toStringAsFixed(1),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: p.ink)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 6)],
      ),
      child: child,
    );
  }
}
