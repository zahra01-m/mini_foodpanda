import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/services/mock_data_service.dart';

/// Every bundled photo the sample data points at must exist on disk, and be
/// covered by the `assets/images/` entry in pubspec.yaml (flat folder only).
void main() {
  bool isBundled(String p) => p.startsWith('assets/');

  test('every sample restaurant and menu image file exists', () {
    final paths = <String>[
      for (final r in MockDataService.restaurants) ...[
        if (isBundled(r.imageAsset)) r.imageAsset,
        if (isBundled(r.imageUrl)) r.imageUrl,
      ],
      for (final m in MockDataService.menuItems)
        if (isBundled(m.imageUrl)) m.imageUrl,
    ];
    expect(paths, isNotEmpty);
    for (final p in paths) {
      expect(File(p).existsSync(), isTrue, reason: 'missing asset file: $p');
      // pubspec lists "assets/images/" which is NOT recursive.
      expect(p.split('/').length, 3, reason: '$p must sit directly in assets/images/');
    }
  });

  test('every sample menu item belongs to a sample restaurant', () {
    final ids = MockDataService.restaurants.map((r) => r.id).toSet();
    for (final m in MockDataService.menuItems) {
      expect(ids.contains(m.restaurantId), isTrue, reason: '${m.name} has an unknown restaurant');
    }
  });
}
