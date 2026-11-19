/// A delivery address the customer saved on this device ("Home", "Work"...).
class SavedAddress {
  final String id;
  final String label;
  final String address;

  /// Optional GPS pin captured with "Use GPS" when the address was saved.
  final double? lat;
  final double? lng;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'address': address, 'lat': lat, 'lng': lng};

  factory SavedAddress.fromJson(Map<String, dynamic> m) => SavedAddress(
        id: m['id'] as String,
        label: (m['label'] as String?) ?? 'Other',
        address: (m['address'] as String?) ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );
}
