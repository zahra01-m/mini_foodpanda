import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Phase 2 — real Firebase Auth + Firestore, replacing the old in-memory
/// stub. AuthProvider's public API (login/signUp/currentUser/logout)
/// didn't need to change, exactly as the Phase 1 comment planned.
///
/// Firestore shape (matches the project spec's `users` collection):
///   users/{uid} -> { uid, name, email, phone, role, createdAt }
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  /// The currently signed-in user, if any — reconstructed from Firestore
  /// so the role is always known. Returns null if nobody is signed in or
  /// their profile document is missing.
  Future<AppUser?> currentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final doc = await _users.doc(fbUser.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(fbUser.uid, doc.data()!);
  }

  Future<AppUser> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      // Shouldn't normally happen (signUp always creates the profile), but
      // guard against a Firebase Auth account with no Firestore profile.
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'No profile found for this account. Please sign up again.',
      );
    }

    final profile = AppUser.fromFirestore(uid, doc.data()!);
    if (profile.role != role) {
      // The same email can only be registered under one role in this
      // simple model — surface that clearly instead of silently
      // logging them in under the wrong dashboard.
      throw FirebaseAuthException(
        code: 'wrong-role',
        message: 'This account is registered as ${profile.role.id}, not ${role.id}.',
      );
    }
    return profile;
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    // Riders need admin approval before they can take orders.
    final user = AppUser(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isApproved: role != UserRole.rider,
    );
    await _users.doc(uid).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await credential.user!.updateDisplayName(name);
    return user;
  }

  Future<void> logout() => _auth.signOut();

  /// Updates the signed-in person's own name and phone (role and approval
  /// are protected by firestore.rules).
  Future<void> updateProfile({required String uid, required String name, required String phone}) =>
      _users.doc(uid).update({'name': name, 'phone': phone});

  /// Emails a password-reset link (Firebase Auth handles the rest).
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  /// Readable message for FirebaseAuthException — the rest of the app
  /// just calls `.toString()` on caught errors today, so this keeps
  /// those messages friendly without touching every call site.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'That email is already registered — try logging in instead.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'wrong-role':
        case 'profile-missing':
          return error.message ?? 'Something went wrong signing you in.';
        default:
          return error.message ?? 'Something went wrong signing you in.';
      }
    }
    return error.toString();
  }
}
