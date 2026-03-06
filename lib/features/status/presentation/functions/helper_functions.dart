import 'package:chat_application/core/utils/image_picker_service.dart';
import 'package:chat_application/core/utils/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HelperFunctions {
  static final _imagePickerService = ImagePickerService();
  
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