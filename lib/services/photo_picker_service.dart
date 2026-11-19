import 'package:image_picker/image_picker.dart';
import '../core/utils/image_data.dart';

/// Lets the admin choose a photo from the gallery and turns it into a small
/// data URI ready to store in `imageUrl` (see image_data.dart for why).
class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  /// Returns null when the admin cancels. Throws [PhotoTooLargeException]
  /// when even the resized photo is bigger than [maxStoredImageBytes].
  Future<String?> pickAsDataUri({int maxSide = 900}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide.toDouble(),
      maxHeight: maxSide.toDouble(),
      imageQuality: 80,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > maxStoredImageBytes) {
      throw PhotoTooLargeException(bytes.length);
    }
    return encodeDataImage(bytes, mime: imageMimeType(file.mimeType, file.name));
  }
}

class PhotoTooLargeException implements Exception {
  final int bytes;
  const PhotoTooLargeException(this.bytes);

  @override
  String toString() =>
      'That photo is ${(bytes / 1024).round()} KB even after resizing '
      '(limit ${maxStoredImageBytes ~/ 1024} KB). Pick a smaller or simpler photo.';
}
