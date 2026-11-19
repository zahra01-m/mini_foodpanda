import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rider_location_model.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider((ref) => LocationService.instance);

/// Live position of one rider, straight from Firestore `riderLocations`.
final riderLocationProvider =
    StreamProvider.autoDispose.family<RiderLocation?, String>((ref, riderId) {
  return ref.watch(locationServiceProvider).watch(riderId);
});

/// Every rider currently sharing a location — for the admin live map.
final allRiderLocationsProvider = StreamProvider.autoDispose<List<RiderLocation>>((ref) {
  return ref.watch(locationServiceProvider).watchAll();
});
