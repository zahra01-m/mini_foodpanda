import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item_model.dart';
import '../services/photo_picker_service.dart';
import '../services/restaurant_service.dart';

final restaurantServiceProvider = Provider((ref) => RestaurantService());

final photoPickerServiceProvider = Provider((ref) => PhotoPickerService());

/// Every restaurant, approved or not — for the admin panel.
final allRestaurantsProvider = StreamProvider.autoDispose<List<Restaurant>>((ref) {
  return ref.watch(restaurantServiceProvider).watchRestaurants();
});

/// What customers see: approved restaurants only, updated live.
final restaurantListProvider = StreamProvider.autoDispose<List<Restaurant>>((ref) {
  return ref
      .watch(restaurantServiceProvider)
      .watchRestaurants()
      .map((list) => list.where((r) => r.isApproved).toList());
});

/// Full menu including unavailable items — for the admin panel.
final adminMenuProvider =
    StreamProvider.autoDispose.family<List<MenuItem>, String>((ref, restaurantId) {
  return ref.watch(restaurantServiceProvider).watchMenu(restaurantId);
});

/// Customer-facing menu: only items marked available.
final menuProvider =
    StreamProvider.autoDispose.family<List<MenuItem>, String>((ref, restaurantId) {
  return ref
      .watch(restaurantServiceProvider)
      .watchMenu(restaurantId)
      .map((list) => list.where((m) => m.available).toList());
});
