import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/restaurant_model.dart';

void main() {
  group('Restaurant', () {
    test('toFirestore stores a GeoPoint and fromFirestore reads it back', () {
      const restaurant = Restaurant(
        id: 'rest-1',
        name: 'Karahi House',
        category: 'Pakistani',
        imageAsset: 'assets/images/restaurant_1.png',
        rating: 4.6,
        etaMinutes: 30,
        lat: 30.05,
        lng: 72.35,
      );
      final data = restaurant.toFirestore();
      expect(data['location'], const GeoPoint(30.05, 72.35));

      final restored = Restaurant.fromFirestore('rest-1', data);
      expect(restored.name, 'Karahi House');
      expect(restored.lat, 30.05);
      expect(restored.lng, 72.35);
      expect(restored.isApproved, true);
    });

    test('fromFirestore falls back to the default location when missing', () {
      final restored = Restaurant.fromFirestore('rest-2', {
        'name': 'No Location Cafe',
        'category': 'Cafe',
      });
      expect(restored.lat, Restaurant.defaultLat);
      expect(restored.lng, Restaurant.defaultLng);
      // Missing rating/eta also fall back to sane defaults.
      expect(restored.rating, 4.0);
      expect(restored.etaMinutes, 30);
    });

    test('copyWith cannot change id, imageAsset or rating', () {
      const restaurant = Restaurant(
        id: 'rest-1',
        name: 'A',
        category: 'B',
        imageAsset: 'img.png',
        rating: 4.5,
        etaMinutes: 20,
      );
      final updated = restaurant.copyWith(name: 'C', isApproved: false);
      expect(updated.id, 'rest-1');
      expect(updated.imageAsset, 'img.png');
      expect(updated.rating, 4.5);
      expect(updated.name, 'C');
      expect(updated.isApproved, false);
    });
  });
}
