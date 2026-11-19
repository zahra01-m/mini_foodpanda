import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/review_model.dart';

void main() {
  group('Review', () {
    test('toFirestore/fromFirestore round-trip', () {
      final createdAt = DateTime(2026, 3, 1, 10, 30);
      final review = Review(
        id: 'order-1',
        orderId: 'order-1',
        restaurantId: 'rest-1',
        customerId: 'cust-1',
        rating: 4,
        comment: 'Tasty!',
        createdAt: createdAt,
      );
      final data = review.toFirestore();
      final restored = Review.fromFirestore('order-1', data);
      expect(restored.orderId, 'order-1');
      expect(restored.restaurantId, 'rest-1');
      expect(restored.customerId, 'cust-1');
      expect(restored.rating, 4);
      expect(restored.comment, 'Tasty!');
      expect(restored.createdAt, createdAt);
    });

    test('fromFirestore falls back to the document id as orderId', () {
      final restored = Review.fromFirestore('order-9', {
        'restaurantId': 'rest-1',
        'customerId': 'cust-1',
      });
      expect(restored.orderId, 'order-9');
      expect(restored.rating, 5);
      expect(restored.comment, '');
    });
  });
}
