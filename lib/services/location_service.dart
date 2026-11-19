import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/firestore_utils.dart';
import '../models/rider_location_model.dart';

/// One-shot device GPS helpers (used by checkout for the delivery point).
class DeviceLocation {
  DeviceLocation._();

  /// Asks for location permission if needed. False if unavailable/denied.
  static Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm != LocationPermission.denied && perm != LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  static Future<Position?> current() async {
    if (!await ensurePermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Rider live location, stored in Firestore `riderLocations/{riderId}`.
///
/// Riders publish their real GPS position while they have an active
/// delivery; customers and the admin dashboard listen to the same
/// documents. Writes are throttled and kept in their own collection so
/// high-frequency updates never touch the order document (as the spec
/// recommends). A demo simulation mode moves the rider along a straight
/// line for emulators that have no real movement.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _doc(String riderId) =>
      _db.collection(Col.riderLocations).doc(riderId);

  Stream<RiderLocation?> watch(String riderId) => _doc(riderId).snapshots().map((snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return RiderLocation.fromFirestore(snap.id, data);
      });

  Stream<List<RiderLocation>> watchAll() =>
      _db.collection(Col.riderLocations).snapshots().map(
            (snap) => snap.docs.map((d) => RiderLocation.fromFirestore(d.id, d.data())).toList(),
          );

  StreamSubscription<Position>? _gpsSub;
  Timer? _simTimer;
  bool _simMode = false;
  bool _starting = false;
  String? _sharingRiderId;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isSimulating => _simMode;

  /// Starts publishing this rider's real GPS position. Safe to call
  /// repeatedly. Returns false if location permission isn't granted.
  Future<bool> ensureSharing({required String riderId, required String orderId}) async {
    if (_simMode) return true;
    if (_gpsSub != null && _sharingRiderId == riderId) return true;
    if (_starting) return _gpsSub != null;
    _starting = true;
    try {
      await _gpsSub?.cancel();
      _gpsSub = null;
      if (!await DeviceLocation.ensurePermission()) return false;
      _sharingRiderId = riderId;
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (pos) {
          final now = DateTime.now();
          if (now.difference(_lastWrite) < const Duration(seconds: 3)) return;
          _lastWrite = now;
          publish(riderId: riderId, orderId: orderId, lat: pos.latitude, lng: pos.longitude);
        },
        onError: (Object e) => debugPrint('GPS stream error: $e'),
      );
      return true;
    } finally {
      _starting = false;
    }
  }

  Future<void> publish({
    required String riderId,
    String? orderId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _doc(riderId).set({
        'riderId': riderId,
        'orderId': orderId,
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not publish rider location: $e');
    }
  }

  /// Demo mode: glide from one point to another over [duration],
  /// publishing to Firestore just like real GPS would.
  void startSimulation({
    required String riderId,
    String? orderId,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    Duration duration = const Duration(seconds: 45),
  }) {
    _gpsSub?.cancel();
    _gpsSub = null;
    _simTimer?.cancel();
    _simMode = true;
    _sharingRiderId = riderId;
    final startedAt = DateTime.now();

    void tick() {
      final f = (DateTime.now().difference(startedAt).inMilliseconds / duration.inMilliseconds)
          .clamp(0.0, 1.0);
      publish(
        riderId: riderId,
        orderId: orderId,
        lat: fromLat + (toLat - fromLat) * f,
        lng: fromLng + (toLng - fromLng) * f,
      );
      if (f >= 1.0) _simTimer?.cancel();
    }

    tick();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
  }

  /// Stops publishing. Pass [clearRiderId] to also remove the rider's
  /// location document (on delivery or logout).
  Future<void> stopSharing({String? clearRiderId}) async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    _simTimer?.cancel();
    _simTimer = null;
    _simMode = false;
    _sharingRiderId = null;
    if (clearRiderId != null) {
      try {
        await _doc(clearRiderId).delete();
      } catch (_) {}
    }
  }
}
