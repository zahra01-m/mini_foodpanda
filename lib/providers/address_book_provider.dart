import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_address.dart';
import 'auth_provider.dart';

/// Saved delivery addresses, stored on-device per signed-in user (so two
/// accounts on one phone don't see each other's addresses, and no
/// Firestore rules change is needed).
class AddressBookNotifier extends StateNotifier<List<SavedAddress>> {
  AddressBookNotifier(this._uid) : super(const []) {
    _load();
  }

  final String? _uid;
  String get _key => 'addresses_$_uid';

  Future<void> _load() async {
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) state = list;
    } catch (_) {
      // Corrupt or unavailable storage: start with an empty address book.
    }
  }

  Future<void> _save() async {
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  /// Adds an address, replacing any existing one with the same label.
  void upsert(SavedAddress a) {
    state = [
      a,
      ...state.where((x) => x.label.toLowerCase() != a.label.toLowerCase() && x.id != a.id),
    ];
    _save();
  }

  void remove(String id) {
    state = state.where((x) => x.id != id).toList();
    _save();
  }
}

final addressBookProvider = StateNotifierProvider<AddressBookNotifier, List<SavedAddress>>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  return AddressBookNotifier(uid);
});
