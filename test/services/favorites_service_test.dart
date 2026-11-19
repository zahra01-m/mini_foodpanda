import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/services/favorites_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FavoritesService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FavoritesService(firestore: firestore);
  });

  group('addFavorite / removeFavorite', () {
    test('addFavorite stores a deterministic doc id', () async {
      await service.addFavorite('cust-1', 'rest-1');
      final doc = await firestore.collection('favorites').doc('cust-1_rest-1').get();
      expect(doc.exists, true);
      expect(doc.data()!['customerId'], 'cust-1');
      expect(doc.data()!['restaurantId'], 'rest-1');
    });

    test('adding the same favorite twice does not create a duplicate document', () async {
      await service.addFavorite('cust-1', 'rest-1');
      await service.addFavorite('cust-1', 'rest-1');
      final all = await firestore.collection('favorites').get();
      expect(all.docs.length, 1);
    });

    test('removeFavorite deletes the doc', () async {
      await service.addFavorite('cust-1', 'rest-1');
      await service.removeFavorite('cust-1', 'rest-1');
      final doc = await firestore.collection('favorites').doc('cust-1_rest-1').get();
      expect(doc.exists, false);
    });
  });

  group('toggleFavorite', () {
    test('adds when currentlyFavorite is false, removes when true', () async {
      await service.toggleFavorite('cust-1', 'rest-1', currentlyFavorite: false);
      expect((await firestore.collection('favorites').doc('cust-1_rest-1').get()).exists, true);

      await service.toggleFavorite('cust-1', 'rest-1', currentlyFavorite: true);
      expect((await firestore.collection('favorites').doc('cust-1_rest-1').get()).exists, false);
    });
  });

  group('watchFavoriteIds', () {
    test('only returns restaurant ids favorited by that customer', () async {
      await service.addFavorite('cust-1', 'rest-1');
      await service.addFavorite('cust-1', 'rest-2');
      await service.addFavorite('cust-2', 'rest-3');

      final ids = await service.watchFavoriteIds('cust-1').first;
      expect(ids, {'rest-1', 'rest-2'});
    });

    test('is empty for a customer with no favorites', () async {
      final ids = await service.watchFavoriteIds('nobody').first;
      expect(ids, isEmpty);
    });
  });
}
