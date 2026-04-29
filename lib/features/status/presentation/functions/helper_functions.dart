
import 'package:chat_application/core/utils/image_picker_service.dart';
import 'package:chat_application/core/utils/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class HelperFunctions {
  static final _imagePickerService = ImagePickerService();

  static Future<bool> hasInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await http
            .get(Uri.parse('https://1.1.1.1'))
            .timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (_) {
        return true;
      }
    }
  }
  
  //function that calls modalbottomsheet class
  static Future<XFile?> showImageSourceBottomSheet(String userId, BuildContext context) async {
    final result = await ModalBottomSheet.show<String>(
      context,
      title: "Select Image Source",
      options: [
        BottomSheetOption(
          value: 'camera',
          label: 'Camera',
          icon: Icons.camera_alt,
        ),
        BottomSheetOption(
          value: 'gallery',
          label: 'Gallery',
          icon: Icons.photo_library,
        ),
      ],
    );

    XFile? image;

    if (result == 'camera') {
      image = await _imagePickerService.pickFromCamera();
    } else if (result == 'gallery') {
      image = await _imagePickerService.pickFromGallery();
    }

    if (image != null) {
      return image;
    }
    return null;
  }
}