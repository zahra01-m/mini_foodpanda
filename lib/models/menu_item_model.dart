import '../core/utils/firestore_utils.dart';
import '../core/utils/sample_images.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final bool available;

  /// Section the dish is listed under on the restaurant page
  /// ("Starters", "Mains", "Drinks"...). Empty = uncategorised.
  final String category;

  /// Optional https photo URL. Empty = themed icon fallback.
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.available = true,
    this.category = '',
    this.imageUrl = '',
  });

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    bool? available,
    String? category,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      available: available ?? this.available,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'available': available,
        'category': category,
        'imageUrl': imageUrl,
      };

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> d) {
    return MenuItem(
      id: id,
      restaurantId: (d['restaurantId'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      price: readDouble(d['price']),
      available: (d['available'] as bool?) ?? true,
      // Older documents don't have these fields yet.
      category: (d['category'] as String?) ?? '',
      imageUrl: resolveBundledImage((d['imageUrl'] as String?) ?? '', sampleMenuImages[id]),
    );
  }
}
