import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';
import 'package:mini_foodpanda/services/mock_data_service.dart';
import 'package:mini_foodpanda/services/restaurant_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late RestaurantService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = RestaurantService(firestore: firestore);
  });

  group('RestaurantService restaurants', () {
    test('saveRestaurant with an empty id creates a new document', () async {
      const restaurant = Restaurant(
        id: '',
        name: 'Zeta Diner',
        category: 'Fast Food',
        imageAsset: 'a.png',
        rating: 4.2,
        etaMinutes: 25,
      );
      await service.saveRestaurant(restaurant);
      final snap = await firestore.collection('restaurants').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['name'], 'Zeta Diner');
    });

    test('saveRestaurant with an existing id updates that document', () async {
      await firestore.collection('restaurants').doc('rest-1').set(
            const Restaurant(id: 'rest-1', name: 'Old', category: 'X', imageAsset: '', rating: 4, etaMinutes: 20)
                .toFirestore(),
          );
      await service.saveRestaurant(
        const Restaurant(id: 'rest-1', name: 'New Name', category: 'X', imageAsset: '', rating: 4, etaMinutes: 20),
      );
      final doc = await firestore.collection('restaurants').doc('rest-1').get();
      expect(doc.data()!['name'], 'New Name');
      final all = await firestore.collection('restaurants').get();
      expect(all.docs.length, 1); // updated in place, not duplicated
    });

    test('watchRestaurants sorts alphabetically by name', () async {
      await firestore.collection('restaurants').doc('a').set(
            const Restaurant(id: 'a', name: 'Zebra Cafe', category: 'x', imageAsset: '', rating: 4, etaMinutes: 10)
                .toFirestore(),
          );
      await firestore.collection('restaurants').doc('b').set(
            const Restaurant(id: 'b', name: 'Apple Diner', category: 'x', imageAsset: '', rating: 4, etaMinutes: 10)
                .toFirestore(),
          );
      final list = await service.watchRestaurants().first;
      expect(list.map((r) => r.name).toList(), ['Apple Diner', 'Zebra Cafe']);
    });

    test('setApproved flips the isApproved flag', () async {
      await firestore.collection('restaurants').doc('r1').set(
            const Restaurant(id: 'r1', name: 'A', category: 'x', imageAsset: '', rating: 4, etaMinutes: 10)
                .toFirestore(),
          );
      await service.setApproved('r1', false);
      final doc = await firestore.collection('restaurants').doc('r1').get();
      expect(doc.data()!['isApproved'], false);
    });

    test('deleteRestaurant removes the restaurant and every menu item under it', () async {
      await firestore.collection('restaurants').doc('r1').set(
            const Restaurant(id: 'r1', name: 'A', category: 'x', imageAsset: '', rating: 4, etaMinutes: 10)
                .toFirestore(),
          );
      await firestore.collection('menuItems').doc('m1').set(
            const MenuItem(id: 'm1', restaurantId: 'r1', name: 'Item', description: '', price: 100).toFirestore(),
          );
      await firestore.collection('menuItems').doc('m2').set(
            const MenuItem(id: 'm2', restaurantId: 'r1', name: 'Item 2', description: '', price: 200).toFirestore(),
          );
      await service.deleteRestaurant('r1');

      expect((await firestore.collection('restaurants').doc('r1').get()).exists, false);
      expect((await firestore.collection('menuItems').get()).docs, isEmpty);
    });

    test('seedSampleData ships only the four restaurants that have photos', () async {
      await service.seedSampleData();
      final restaurants = await firestore.collection('restaurants').get();
      expect(restaurants.docs.map((d) => d.id).toSet(),
          {'sample-midcity', 'sample-fifth-avenue', 'sample-sweet-creme', 'sample-brew-bean'});
      for (final r in MockDataService.restaurants) {
        expect(r.imageAsset, isNotEmpty, reason: '${r.name} needs a bundled photo');
      }
    });

    test('seedSampleData removes sample vendors from older seeds', () async {
      await firestore.collection('restaurants').doc('sample-dragon-wok').set({'name': 'Dragon Wok'});
      await firestore.collection('menuItems').doc('sample-wok-1').set({'name': 'Manchurian', 'restaurantId': 'sample-dragon-wok'});
      await firestore.collection('restaurants').doc('my-own-vendor').set({'name': 'Mine'});

      await service.seedSampleData();

      expect((await firestore.collection('restaurants').doc('sample-dragon-wok').get()).exists, isFalse);
      expect((await firestore.collection('menuItems').doc('sample-wok-1').get()).exists, isFalse);
      // Only retired sample ids are touched; an admin's own vendor stays.
      expect((await firestore.collection('restaurants').doc('my-own-vendor').get()).exists, isTrue);
    });

    test('seedSampleData writes every built-in sample restaurant and menu item', () async {
      await service.seedSampleData();
      final restaurants = await firestore.collection('restaurants').get();
      final menu = await firestore.collection('menuItems').get();
      expect(restaurants.docs.length, greaterThanOrEqualTo(1));
      expect(menu.docs.length, greaterThanOrEqualTo(1));

      // Seeding twice must not create duplicates — fixed sample ids.
      await service.seedSampleData();
      final restaurantsAgain = await firestore.collection('restaurants').get();
      expect(restaurantsAgain.docs.length, restaurants.docs.length);
    });
  });

  group('RestaurantService menu items', () {
    test('saveMenuItem creates then setAvailable/deleteMenuItem manage it', () async {
      await service.saveMenuItem(
        const MenuItem(id: '', restaurantId: 'r1', name: 'Burger', description: '', price: 400),
      );
      final created = await firestore.collection('menuItems').get();
      expect(created.docs.length, 1);
      final id = created.docs.first.id;

      await service.setAvailable(id, false);
      expect((await firestore.collection('menuItems').doc(id).get()).data()!['available'], false);

      await service.deleteMenuItem(id);
      expect((await firestore.collection('menuItems').doc(id).get()).exists, false);
    });

    test('watchMenu only returns items for the given restaurant, sorted by name', () async {
      await firestore.collection('menuItems').add(
            const MenuItem(id: '', restaurantId: 'r1', name: 'Zucchini Wrap', description: '', price: 300)
                .toFirestore(),
          );
      await firestore.collection('menuItems').add(
            const MenuItem(id: '', restaurantId: 'r1', name: 'Apple Pie', description: '', price: 150)
                .toFirestore(),
          );
      await firestore.collection('menuItems').add(
            const MenuItem(id: '', restaurantId: 'r2', name: 'Other Restaurant Item', description: '', price: 100)
                .toFirestore(),
          );
      final list = await service.watchMenu('r1').first;
      expect(list.map((m) => m.name).toList(), ['Apple Pie', 'Zucchini Wrap']);
    });
  });
}
