import 'package:flutter/material.dart';
import 'food_loader.dart';

/// Default full-screen loading state. Every screen that already used
/// `AppLoading()` now gets the food-themed [FoodLoader] automatically.
class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) => FoodLoader(message: message);
}
