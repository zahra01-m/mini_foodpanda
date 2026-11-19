import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/review_model.dart';
import 'package:mini_foodpanda/services/review_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReviewService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ReviewService(firestore: firestore);
  });

  group('submitReview', () {
    test('stores the review keyed by order id, so one order = one review', () async {
      await service.submitReview(
        orderId: 'order-1',
        restaurantId: 'rest-1',
        customerId: 'cust-1',
        rating: 5,
        comment: 'Great!',
      );
      final doc = await firestore.collection('reviews').doc('order-1').get();
      expect(doc.exists, true);
      expect(doc.data()!['rating'], 5);

      // Re-submitting for the same order overwrites rather than duplicating.
      await service.submitReview(
        orderId: 'order-1',
        restaurantId: 'rest-1',
        customerId: 'cust-1',
        rating: 2,
        comment: 'Actually not great',
      );
      final all = await firestore.collection('reviews').get();
      expect(all.docs.length, 1);
      expect(all.docs.first.data()['rating'], 2);
    });
  });

  group('watchReviews', () {
    test('returns only the given restaurant\'s reviews, newest first', () async {
      await service.submitReview(orderId: 'o1', restaurantId: 'r1', customerId: 'c1', rating: 4, comment: 'a');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.submitReview(orderId: 'o2', restaurantId: 'r1', customerId: 'c2', rating: 5, comment: 'b');
      await service.submitReview(orderId: 'o3', restaurantId: 'r2', customerId: 'c1', rating: 1, comment: 'c');

      final list = await service.watchReviews('r1').first;
      expect(list.map((r) => r.orderId).toList(), ['o2', 'o1']);
    });
  });

  group('watchReviewedOrderIds', () {
    test('lists the order ids a customer has already reviewed', () async {
      await service.submitReview(orderId: 'o1', restaurantId: 'r1', customerId: 'cust-1', rating: 4, comment: '');
      await service.submitReview(orderId: 'o2', restaurantId: 'r1', customerId: 'cust-2', rating: 3, comment: '');
      final ids = await service.watchReviewedOrderIds('cust-1').first;
      expect(ids, {'o1'});
    });
  });

  group('averageOf', () {
    test('averages the star ratings', () {
      final reviews = [
        Review(id: '1', orderId: '1', restaurantId: 'r', customerId: 'c', rating: 5, comment: '', createdAt: DateTime(2026)),
        Review(id: '2', orderId: '2', restaurantId: 'r', customerId: 'c', rating: 3, comment: '', createdAt: DateTime(2026)),
      ];
      expect(ReviewService.averageOf(reviews), 4);
    });

    test('is zero when there are no reviews', () {
      expect(ReviewService.averageOf(const []), 0);
    });
  });
}
