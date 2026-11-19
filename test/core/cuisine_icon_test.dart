import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/cuisine_icon.dart';

void main() {
  test('known cuisines map to their own icon', () {
    expect(cuisineIcon('Pizza'), Icons.local_pizza_rounded);
    expect(cuisineIcon('Fast Food'), Icons.fastfood_rounded);
    expect(cuisineIcon('Desserts'), Icons.cake_rounded);
    expect(cuisineIcon('Pakistani'), Icons.dinner_dining_rounded);
  });

  test('matching is case-insensitive and unknown categories get a default', () {
    expect(cuisineIcon('CAFE'), Icons.local_cafe_rounded);
    expect(cuisineIcon('Something new'), Icons.restaurant_rounded);
  });
}
