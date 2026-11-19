import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import 'mock_data_service.dart';

/// Firestore-backed `restaurants` and `menuItems` collections.
/// Queries use a single equality filter and sort on the client, so no
/// composite indexes are needed.
class RestaurantService {
  RestaurantService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _restaurants => _db.collection(Col.restaurants);
  CollectionReference<Map<String, dynamic>> get _menu => _db.collection(Col.menuItems);

  Stream<List<Restaurant>> watchRestaurants() => _restaurants.snapshots().map((snap) {
        final list = snap.docs.map((d) => Restaurant.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Stream<List<MenuItem>> watchMenu(String restaurantId) =>
      _menu.where('restaurantId', isEqualTo: restaurantId).snapshots().map((snap) {
        final list = snap.docs.map((d) => MenuItem.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  /// Creates the restaurant when [r.id] is empty, otherwise updates it.
  Future<void> saveRestaurant(Restaurant r) async {
    final doc = r.id.isEmpty ? _restaurants.doc() : _restaurants.doc(r.id);
    await doc.set(r.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setApproved(String restaurantId, bool approved) =>
      _restaurants.doc(restaurantId).update({'isApproved': approved});

  /// Deletes the restaurant and all of its menu items.
  Future<void> deleteRestaurant(String restaurantId) async {
    final items = await _menu.where('restaurantId', isEqualTo: restaurantId).get();
    final batch = _db.batch();
    for (final d in items.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_restaurants.doc(restaurantId));
    await batch.commit();
  }

  /// Creates the item when [item.id] is empty, otherwise updates it.
  Future<void> saveMenuItem(MenuItem item) async {
    final doc = item.id.isEmpty ? _menu.doc() : _menu.doc(item.id);
    await doc.set(item.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setAvailable(String itemId, bool available) =>
      _menu.doc(itemId).update({'available': available});

  Future<void> deleteMenuItem(String itemId) => _menu.doc(itemId).delete();

  /// Writes the built-in sample restaurants and menus (admin only).
  Future<void> seedSampleData() async {
    final batch = _db.batch();
    for (final r in MockDataService.restaurants) {
      batch.set(_restaurants.doc(r.id), r.toFirestore());
    }
    for (final m in MockDataService.menuItems) {
      batch.set(_menu.doc(m.id), m.toFirestore());
    }
    // Sample vendors that earlier versions of the seed created but that no
    // longer ship (they had no photos). Deleting a missing doc is a no-op.
    for (final id in MockDataService.retiredRestaurantIds) {
      batch.delete(_restaurants.doc(id));
    }
    for (final id in MockDataService.retiredMenuItemIds) {
      batch.delete(_menu.doc(id));
    }
    await batch.commit();
  }
}
