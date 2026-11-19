import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../models/user_model.dart';

/// Reads of `users/{uid}` beyond login, plus rider approval for admins.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection(Col.users);

  Stream<AppUser?> watchUser(String uid) => _users.doc(uid).snapshots().map((snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return AppUser.fromFirestore(snap.id, data);
      });

  Stream<List<AppUser>> watchRiders() =>
      _users.where('role', isEqualTo: UserRole.rider.id).snapshots().map((snap) {
        final list = snap.docs.map((d) => AppUser.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Future<void> setApproved(String uid, bool approved) =>
      _users.doc(uid).update({'isApproved': approved});
}
