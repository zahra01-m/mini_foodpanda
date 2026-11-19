import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/rider_service.dart';

final riderServiceProvider = Provider((ref) => RiderService());

/// Requests this rider declined in the current session (hidden locally;
/// other riders still see them).
final declinedRequestsProvider = StateProvider<Set<String>>((ref) => <String>{});

final incomingRequestsProvider = StreamProvider.autoDispose<List<FoodOrder>>((ref) {
  final declined = ref.watch(declinedRequestsProvider);
  return ref
      .watch(riderServiceProvider)
      .watchIncomingRequests()
      .map((list) => list.where((o) => !declined.contains(o.id)).toList());
});

final activeDeliveryProvider =
    StreamProvider.autoDispose.family<FoodOrder?, String>((ref, riderId) {
  return ref.watch(riderServiceProvider).watchActiveDelivery(riderId);
});

final riderHistoryProvider =
    StreamProvider.autoDispose.family<List<FoodOrder>, String>((ref, riderId) {
  return ref.watch(riderServiceProvider).watchHistory(riderId);
});

final riderEarningsProvider = Provider.autoDispose.family<double, String>((ref, riderId) {
  final history = ref.watch(riderHistoryProvider(riderId)).valueOrNull ?? const <FoodOrder>[];
  return RiderService.earningsOf(history);
});
