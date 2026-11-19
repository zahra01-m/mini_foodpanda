import 'dart:convert';
import 'dart:typed_data';

/// Photos picked by an admin are stored *inside* the Firestore document as a
/// `data:image/...;base64,...` string. That keeps the app working on the free
/// Firebase plan (Cloud Storage now needs a billing account) — the picker
/// shrinks every photo first, so a document stays far below Firestore's 1 MiB
/// limit. Anything that is not a data URI is treated as a normal https URL or
/// a bundled asset path.
bool isDataImage(String value) => value.startsWith('data:image/');

/// Largest photo (bytes, after the picker has resized it) we will store.
const int maxStoredImageBytes = 600 * 1024;

String encodeDataImage(Uint8List bytes, {String mime = 'image/jpeg'}) =>
    'data:$mime;base64,${base64Encode(bytes)}';

final Map<String, Uint8List> _decoded = {};

/// Decodes a data URI (null when it is malformed). Results are cached so a
/// rebuilding list does not base64-decode the same photo every frame.
Uint8List? decodeDataImage(String value) {
  if (!isDataImage(value)) return null;
  final cached = _decoded[value];
  if (cached != null) return cached;
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    final bytes = base64Decode(value.substring(comma + 1));
    if (_decoded.length >= 48) _decoded.remove(_decoded.keys.first);
    _decoded[value] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

/// MIME type for a picked file; falls back to the file name's extension.
String imageMimeType(String? reported, String fileName) {
  if (reported != null && reported.startsWith('image/')) return reported;
  final ext = fileName.toLowerCase().split('.').last;
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}
