import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  final ImagePicker _picker = ImagePicker();

  ImagePickerService._internal();

  factory ImagePickerService() {
    return _instance;
  }

  /// Pick image from camera
  /// Returns XFile if successful, null if cancelled or error
  Future<XFile?> pickFromCamera({
    double maxWidth = 1800,
    double maxHeight = 1800,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      //print('Error picking image from camera: $e');
      return null;
    }
  }


  /// Pick image from gallery
  /// Returns XFile if successful, null if cancelled or error
  Future<XFile?> pickFromGallery({
    double maxWidth = 1800,
    double maxHeight = 1800,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      //print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from either camera or gallery
  /// Returns XFile if successful, null if cancelled or error
  Future<XFile?> pickImage({
    required ImageSource source,
    double maxWidth = 1800,
    double maxHeight = 1800,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      //print('Error picking image: $e');
      return null;
    }
  }
}