import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../core/utils/sample_images.dart';

class Restaurant {
  /// Fallback map position (Vehari) used when a restaurant has no location.
  static const double defaultLat = 30.0453;
  static const double defaultLng = 72.3489;

  final String id;
  final String name;
  final String category;
  final String imageAsset;

  /// Photo shown on cards and the detail header. Empty = use the
  /// gradient/icon fallback. Paste any https image URL (e.g. Firebase
  /// Storage) in the admin restaurant form.
  final String imageUrl;
  final double rating;
  final int etaMinutes;
  final bool isApproved;
  final double lat;
  final double lng;

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.imageAsset,
    this.imageUrl = '',
    required this.rating,
    required this.etaMinutes,
    this.isApproved = true,
    this.lat = defaultLat,
    this.lng = defaultLng,
  });

  Restaurant copyWith({
    String? name,
    String? category,
    String? imageUrl,
    int? etaMinutes,
    bool? isApproved,
    double? lat,
    double? lng,
  }) {
    return Restaurant(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageAsset: imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      isApproved: isApproved ?? this.isApproved,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  /// Matches the `restaurants` collection in the spec:
  /// id, name, image, category, location, isApproved.
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'rating': rating,
        'etaMinutes': etaMinutes,
        'isApproved': isApproved,
        'location': GeoPoint(lat, lng),
      };

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> d) {
    final loc = d['location'];
    return Restaurant(
      id: id,
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      imageAsset: resolveBundledImage((d['imageAsset'] as String?) ?? '', sampleRestaurantImages[id]),
      imageUrl: (d['imageUrl'] as String?) ?? '',
      rating: readDouble(d['rating'], 4.0),
      etaMinutes: (d['etaMinutes'] as num?)?.toInt() ?? 30,
      isApproved: (d['isApproved'] as bool?) ?? true,
      lat: loc is GeoPoint ? loc.latitude : defaultLat,
      lng: loc is GeoPoint ? loc.longitude : defaultLng,
    );
  }
}
