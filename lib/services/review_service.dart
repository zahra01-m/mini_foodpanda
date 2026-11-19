import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../models/review_model.dart';

/// Firestore `reviews` collection. The document id is the order id, so an
/// order can only ever be reviewed once.
class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.reviews);

  Future<void> submitReview({
    required String orderId,
    required String restaurantId,
    required String customerId,
    required int rating,
    required String comment,
  }) {
    return _col.doc(orderId).set(Review(
          id: orderId,
          orderId: orderId,
          restaurantId: restaurantId,
          customerId: customerId,
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  Stream<List<Review>> watchReviews(String restaurantId) =>
      _col.where('restaurantId', isEqualTo: restaurantId).snapshots().map((snap) {
        final list = snap.docs.map((d) => Review.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  /// Ids of orders this customer has already reviewed.
  Stream<Set<String>> watchReviewedOrderIds(String customerId) =>
      _col.where('customerId', isEqualTo: customerId).snapshots().map(
            (snap) => snap.docs.map((d) => (d.data()['orderId'] as String?) ?? d.id).toSet(),
          );

  static double averageOf(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    return reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
  }
}
