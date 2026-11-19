import '../core/utils/firestore_utils.dart';

/// One document in `riderLocations/{riderId}` — real latitude/longitude.
class RiderLocation {
  final String riderId;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const RiderLocation({
    required this.riderId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory RiderLocation.fromFirestore(String id, Map<String, dynamic> d) {
    return RiderLocation(
      riderId: id,
      lat: readDouble(d['lat']),
      lng: readDouble(d['lng']),
      updatedAt: readDate(d['updatedAt']),
    );
  }
}
