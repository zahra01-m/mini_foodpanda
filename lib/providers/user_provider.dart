import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider((ref) => UserService());

/// Live profile for one user (approval status, name, phone).
final userProfileProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(userServiceProvider).watchUser(uid);
});

/// All rider accounts — for the admin rider-management screen.
final ridersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).watchRiders();
});
