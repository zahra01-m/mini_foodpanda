import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  AuthState copyWith({AppUser? user, bool? loading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState()) {
    _restoreSession();
  }
  final AuthService _service;

  /// Firebase Auth persists sessions across app restarts — if there's
  /// already a signed-in user (and their Firestore profile still
  /// exists), pick them straight back up instead of forcing a fresh
  /// login every launch.
  Future<void> _restoreSession() async {
    try {
      final user = await _service.currentUser();
      if (user != null) state = state.copyWith(user: user);
    } catch (_) {
      // No harm in staying logged out if this fails — user just logs in again.
    }
  }

  Future<void> login(String email, String password, UserRole role) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _service.login(email: email, password: password, role: role);
      state = state.copyWith(user: user, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: AuthService.messageFor(e));
    }
  }

  Future<void> signUp(String name, String email, String password, String phone, UserRole role) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _service.signUp(name: name, email: email, password: password, phone: phone, role: role);
      state = state.copyWith(user: user, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: AuthService.messageFor(e));
    }
  }

  /// Saves a new name / phone for the current user and refreshes local state.
  /// Throws if the write fails so the UI can show the reason.
  Future<void> updateProfile(String name, String phone) async {
    final user = state.user;
    if (user == null) return;
    await _service.updateProfile(uid: user.id, name: name, phone: phone);
    state = state.copyWith(user: user.copyWith(name: name, phone: phone));
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
