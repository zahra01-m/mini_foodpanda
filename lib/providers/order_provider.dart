import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final customerOrdersProvider =
    StreamProvider.autoDispose.family<List<FoodOrder>, String>((ref, customerId) {
  return ref.watch(orderServiceProvider).watchCustomerOrders(customerId);
});

final allOrdersProvider = StreamProvider.autoDispose<List<FoodOrder>>((ref) {
  return ref.watch(orderServiceProvider).watchAllOrders();
});

/// One order, live — the tracking and order-detail screens watch this.
final orderProvider = StreamProvider.autoDispose.family<FoodOrder?, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).watchOrder(orderId);
});

final placeOrderProvider = Provider((ref) => ref.read(orderServiceProvider));
