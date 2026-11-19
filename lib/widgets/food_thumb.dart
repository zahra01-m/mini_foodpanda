import 'package:flutter/material.dart';
import '../core/utils/image_data.dart';
import '../core/theme/app_palette.dart';
import 'shimmer_box.dart';

/// Square dish photo. Shimmers while loading, fades in, and falls back to
/// a themed icon (chosen from the dish name / category) when there is no
/// URL or the image fails — so the menu never shows broken-image boxes.
class FoodThumb extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String category;
  final double size;
  final double radius;

  const FoodThumb({
    super.key,
    required this.imageUrl,
    required this.name,
    this.category = '',
    this.size = 76,
    this.radius = 16,
  });

  static IconData iconFor(String text) {
    final t = text.toLowerCase();
    bool has(List<String> words) => words.any(t.contains);
    if (has(['pizza'])) return Icons.local_pizza_rounded;
    if (has(['burger', 'sandwich', 'wrap', 'shawarma'])) return Icons.lunch_dining_rounded;
    if (has(['fries', 'nugget', 'fast'])) return Icons.fastfood_rounded;
    if (has(['kabab', 'kebab', 'bbq', 'tikka', 'karahi', 'grill', 'steak', 'seekh'])) {
      return Icons.kebab_dining_rounded;
    }
    if (has(['naan', 'bread', 'roti', 'paratha', 'bake', 'bun'])) return Icons.bakery_dining_rounded;
    if (has(['rice', 'biryani', 'pulao', 'bowl'])) return Icons.rice_bowl_rounded;
    if (has(['noodle', 'soup', 'ramen', 'pasta'])) return Icons.ramen_dining_rounded;
    if (has(['cake', 'dessert', 'ice', 'sweet', 'kheer', 'kulfi', 'brownie'])) return Icons.icecream_rounded;
    if (has(['coffee', 'tea', 'chai', 'latte'])) return Icons.local_cafe_rounded;
    if (has(['juice', 'drink', 'shake', 'lassi', 'cola', 'soda', 'water'])) return Icons.local_drink_rounded;
    if (has(['salad', 'healthy', 'vegan', 'green'])) return Icons.eco_rounded;
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _fallback(context)
            : isDataImage(url)
            ? _memory(context, url)
            : url.startsWith('assets/')
            ? Image.asset(
                url,
                fit: BoxFit.cover,
                // Decode at display size, not at the 800px the file is stored at.
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (context, _, __) => _fallback(context),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, sync) {
                  if (sync) return child;
                  if (frame == null) return ShimmerBox(width: size, height: size, borderRadius: BorderRadius.zero);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, v, c) => Opacity(opacity: v, child: c),
                    child: child,
                  );
                },
                errorBuilder: (context, _, __) => _fallback(context),
              ),
      ),
    );
  }

  Widget _memory(BuildContext context, String url) {
    final bytes = decodeDataImage(url);
    if (bytes == null) return _fallback(context);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (context, _, __) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.redTint, p.beige1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(iconFor('$name $category'), size: size * 0.42, color: p.redDeep)),
    );
  }
}
