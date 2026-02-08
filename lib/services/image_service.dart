import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from appropriate source based on platform
  static Future<ImageResult> pickImageFromSource({
    required ImageSource source,
    double maxWidth = 800.0,
    double maxHeight = 800.0,
    int imageQuality = 85,
  }) async {
    try {
      if (kIsWeb) {
        // Web platform - return XFile directly
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        
        return ImageResult(webImage: image);
      } else {
        // Mobile/Desktop platforms
        if (source == ImageSource.camera) {
          // Check if camera is available on this platform
          if (!await _isCameraAvailable()) {
            throw Exception('Camera is not available on this device');
          }
        }

        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );

        File? file;
        if (image != null) {
          file = File(image.path);
        }

        return ImageResult(file: file);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Check if camera is available on this platform
  static Future<bool> _isCameraAvailable() async {
    if (kIsWeb) {
      // Web camera availability check - simplified for now
      return true; // Most modern browsers support camera
    } else {
      // For mobile/desktop, assume camera is available
      // In a real app, you might want to check platform-specific capabilities
      return true;
    }
  }

  /// Check if gallery/file picker is available
  static Future<bool> isGalleryAvailable() async {
    if (kIsWeb) {
      // Web always has file picker capability
      return true;
    } else {
      // For mobile/desktop, assume gallery is available
      // In a real app, you might want to check platform-specific capabilities
      return true;
    }
  }

  /// Get platform-specific image source options
  static List<ImageSource> getAvailableImageSources() {
    final List<ImageSource> sources = [];
    
    if (kIsWeb) {
      // Web typically supports gallery and sometimes camera
      sources.add(ImageSource.gallery);
      // Camera availability depends on browser permissions
    } else {
      // Mobile/Desktop platforms
      sources.add(ImageSource.gallery);
      sources.add(ImageSource.camera);
    }
    
    return sources;
  }
}

/// Result class to handle different image types for different platforms
class ImageResult {
  final File? file;
  final XFile? webImage;

  ImageResult({this.file, this.webImage});
}
