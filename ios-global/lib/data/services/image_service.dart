// Image service (Global - shared logic)
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Image selection result
class SelectedImage {
  final String path;
  final String? name;
  final int? size;

  const SelectedImage({
    required this.path,
    this.name,
    this.size,
  });
}

/// Image selection service
/// NOTE: Images are selected locally only; upload is reserved for future API integration.
class ImageService {
  static final _picker = ImagePicker();

  /// Pick image from gallery
  static Future<SelectedImage?> pickImage({int maxWidth = 1024}) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        imageQuality: 85,
      );
      if (image != null) {
        return SelectedImage(
          path: image.path,
          name: image.name,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ImageService] Pick image error: $e');
      return null;
    }
  }

  /// Take photo with camera
  static Future<SelectedImage?> takePhoto({int maxWidth = 1024}) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        imageQuality: 85,
      );
      if (image != null) {
        return SelectedImage(
          path: image.path,
          name: image.name,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ImageService] Take photo error: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<SelectedImage>> pickMultipleImages({int maxImages = 9}) async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      return images
          .take(maxImages)
          .map((img) => SelectedImage(path: img.path, name: img.name))
          .toList();
    } catch (e) {
      debugPrint('[ImageService] Pick multiple images error: $e');
      return [];
    }
  }

  /// Upload image to server (reserved for future)
  /// TODO: Implement when backend upload API is ready
  static Future<String?> uploadImage(String localPath) async {
    debugPrint('[ImageService] Upload not implemented yet - reserved for future API');
    // Placeholder: will call backend /api/v1/chat/upload
    return null;
  }
}
