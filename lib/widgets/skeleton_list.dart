import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import 'shimmer_box.dart';

/// A shimmering placeholder shaped like a simple row — leading icon box,
/// two text lines, optional trailing chip. Matches the plain `ListTile`
/// layout used by order history, notifications, delivery history, and
/// the admin/rider management lists, so the loading state previews the
/// shape of what's about to arrive instead of just showing a spinner.
class SkeletonTileList extends StatelessWidget {
  final int itemCount;
  final bool showTrailing;
  final EdgeInsetsGeometry padding;

  const SkeletonTileList({
    super.key,
    this.itemCount = 6,
    this.showTrailing = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const ShimmerBox(width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(10))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160 + (i % 3) * 30, height: 14),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 100, height: 11),
                ],
              ),
            ),
            if (showTrailing) ...[
              const SizedBox(width: 14),
              const ShimmerBox(width: 48, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
            ],
          ],
        ),
      ),
    );
  }
}

/// A shimmering placeholder shaped like [RestaurantCard] — a rounded
/// card with a large photo block on top, then a name line, a category
/// line and a rating pill (the same photo-first layout as the real card,
/// so the list doesn't visibly "jump" when data arrives).
class SkeletonRestaurantList extends StatelessWidget {
  final int itemCount;
  const SkeletonRestaurantList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(height: 150, borderRadius: BorderRadius.zero),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 140 + (i % 2) * 40, height: 16),
                          const SizedBox(height: 8),
                          const ShimmerBox(width: 90, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const ShimmerBox(width: 52, height: 26, borderRadius: BorderRadius.all(Radius.circular(999))),
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
