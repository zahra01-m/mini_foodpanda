import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/image_data.dart';

void main() {
  test('data URIs round-trip', () {
    final bytes = Uint8List.fromList(List.generate(300, (i) => i % 256));
    final uri = encodeDataImage(bytes, mime: 'image/png');
    expect(uri.startsWith('data:image/png;base64,'), isTrue);
    expect(isDataImage(uri), isTrue);
    expect(decodeDataImage(uri), bytes);
    // Second call is served from the cache and still equal.
    expect(decodeDataImage(uri), bytes);
  });

  test('non data-URI and malformed values decode to null', () {
    expect(isDataImage('https://x.com/a.jpg'), isFalse);
    expect(isDataImage('assets/images/a.jpg'), isFalse);
    expect(decodeDataImage('https://x.com/a.jpg'), isNull);
    expect(decodeDataImage('data:image/png;base64'), isNull);
    expect(decodeDataImage('data:image/png;base64,@@@not-base64@@@'), isNull);
  });

  test('mime type comes from the picker, else from the extension', () {
    expect(imageMimeType('image/webp', 'a.jpg'), 'image/webp');
    expect(imageMimeType(null, 'Photo.PNG'), 'image/png');
    expect(imageMimeType('application/octet-stream', 'x.webp'), 'image/webp');
    expect(imageMimeType(null, 'x.heic'), 'image/jpeg');
  });
}
