import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

final restaurantReviewsProvider =
    StreamProvider.autoDispose.family<List<Review>, String>((ref, restaurantId) {
  return ref.watch(reviewServiceProvider).watchReviews(restaurantId);
});

final restaurantRatingProvider = Provider.autoDispose.family<double, String>((ref, restaurantId) {
  final reviews = ref.watch(restaurantReviewsProvider(restaurantId)).valueOrNull ?? const <Review>[];
  return ReviewService.averageOf(reviews);
});

/// Ids of the orders a customer has already reviewed.
final reviewedOrderIdsProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, customerId) {
  return ref.watch(reviewServiceProvider).watchReviewedOrderIds(customerId);
});
