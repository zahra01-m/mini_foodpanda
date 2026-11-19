import 'package:flutter/material.dart';

/// One icon per cuisine / category, shared by the home chips and the
/// restaurant image fallback so they always agree.
IconData cuisineIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('pizza')) return Icons.local_pizza_rounded;
  if (c.contains('fast') || c.contains('burger')) return Icons.fastfood_rounded;
  if (c.contains('cafe') || c.contains('coffee')) return Icons.local_cafe_rounded;
  if (c.contains('health') || c.contains('salad') || c.contains('vegan')) return Icons.eco_rounded;
  if (c.contains('dessert') || c.contains('bake') || c.contains('sweet')) return Icons.cake_rounded;
  if (c.contains('pakistani') || c.contains('desi') || c.contains('bbq')) return Icons.dinner_dining_rounded;
  if (c.contains('chinese') || c.contains('noodle') || c.contains('asian')) return Icons.ramen_dining_rounded;
  return Icons.restaurant_rounded;
}
