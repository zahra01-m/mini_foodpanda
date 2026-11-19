import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorites_service.dart';
import 'auth_provider.dart';

final favoritesServiceProvider = Provider((ref) => FavoritesService());

/// The signed-in customer's favorited restaurant ids, live from Firestore.
final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(favoritesServiceProvider).watchFavoriteIds(uid);
});

/// Whether the restaurant list is currently showing favorites only —
/// a plain client-side filter toggle, not persisted.
final favoritesFilterProvider = StateProvider<bool>((ref) => false);
