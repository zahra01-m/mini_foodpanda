import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/sample_images.dart';

void main() {
  test('every mapped sample image exists on disk', () {
    for (final p in [...sampleRestaurantImages.values, ...sampleMenuImages.values]) {
      expect(File(p).existsSync(), isTrue, reason: 'missing $p');
    }
  });

  test('empty or stale stored paths resolve to the bundled sample photo', () {
    expect(resolveBundledImage('', 'assets/images/a.jpg'), 'assets/images/a.jpg');
    expect(resolveBundledImage('assets/images/restaurant_1.png', 'assets/images/a.jpg'), 'assets/images/a.jpg');
    expect(resolveBundledImage('https://x.com/p.jpg', 'assets/images/a.jpg'), 'https://x.com/p.jpg');
    expect(resolveBundledImage('', null), '');
  });
}
