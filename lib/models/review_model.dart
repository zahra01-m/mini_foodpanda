import '../core/utils/firestore_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String orderId;
  final String restaurantId;
  final String customerId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    required this.customerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'restaurantId': restaurantId,
        'customerId': customerId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Review.fromFirestore(String id, Map<String, dynamic> d) {
    return Review(
      id: id,
      orderId: (d['orderId'] as String?) ?? id,
      restaurantId: (d['restaurantId'] as String?) ?? '',
      customerId: (d['customerId'] as String?) ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 5,
      comment: (d['comment'] as String?) ?? '',
      createdAt: readDate(d['createdAt']),
    );
  }
}
