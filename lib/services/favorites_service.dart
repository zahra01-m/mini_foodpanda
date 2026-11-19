import 'package:cloud_firestore/cloud_firestore.dart';

/// A customer's bookmarked restaurants, stored in a top-level
/// `favorites` collection with a deterministic doc id
/// (`{customerId}_{restaurantId}`) rather than an auto-generated one —
/// that makes "is this already a favorite" a plain doc lookup instead of
/// a query, and makes a double-tap naturally idempotent.
class FavoritesService {
  FavoritesService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('favorites');

  String _docId(String customerId, String restaurantId) => '${customerId}_$restaurantId';

  Stream<Set<String>> watchFavoriteIds(String customerId) {
    return _col.where('customerId', isEqualTo: customerId).snapshots().map(
          (snap) => snap.docs.map((d) => (d.data()['restaurantId'] as String?) ?? '').toSet(),
        );
  }

  Future<void> addFavorite(String customerId, String restaurantId) {
    return _col.doc(_docId(customerId, restaurantId)).set({
      'customerId': customerId,
      'restaurantId': restaurantId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String customerId, String restaurantId) {
    return _col.doc(_docId(customerId, restaurantId)).delete();
  }

  /// Convenience for a heart-icon tap — the caller already knows the
  /// current state from [watchFavoriteIds], so it just says which way to
  /// flip rather than this service re-reading to find out.
  Future<void> toggleFavorite(String customerId, String restaurantId, {required bool currentlyFavorite}) {
    return currentlyFavorite
        ? removeFavorite(customerId, restaurantId)
        : addFavorite(customerId, restaurantId);
  }
}
