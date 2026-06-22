import 'dart:typed_data';

import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/image_picker_service.dart';
import 'package:chat_application/core/utils/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEventResult {
  final String title;
  final String content;
  final XFile? image;

  AddEventResult({
    required this.title,
    required this.content,
    this.image,
  });
}

class AddEventDialog {
  static final _imagePickerService = ImagePickerService();

  static Future<AddEventResult?> show(BuildContext context) async {
    final titleController = TextEditingController(text: "New Note");
    final contentController = TextEditingController();
    Uint8List? pickedImageBytes;
    XFile? pickedImage;

    return await showDialog<AddEventResult>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppPallete.transparentColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPallete.cardBg,
                        AppPallete.darkTertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppPallete.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppPallete.primaryOrange,
                                    AppPallete.lightOrange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                pickedImageBytes != null
                                    ? Icons.image_outlined
                                    : Icons.note_add_outlined,
                                color: AppPallete.whiteColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Add Note",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.whiteColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleController,
                          style: const TextStyle(
                            color: AppPallete.whiteColor,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: "Title",
                            labelStyle: const TextStyle(color: AppPallete.greyText),
                            filled: true,
                            fillColor: AppPallete.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.divider,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.divider,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contentController,
                          maxLines: 5,
                          style: const TextStyle(
                            color: AppPallete.whiteColor,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: "Content",
                            alignLabelWithHint: true,
                            labelStyle: const TextStyle(color: AppPallete.greyText),
                            filled: true,
                            fillColor: AppPallete.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.divider,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.divider,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppPallete.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        if (pickedImageBytes != null) ...[
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  pickedImageBytes!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      pickedImageBytes = null;
                                      pickedImage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (pickedImageBytes == null)
                              TextButton.icon(
                                onPressed: () async {
                                  final source = await ModalBottomSheet.show<String>(
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
                                  if (source == 'camera') {
                                    image = await _imagePickerService.pickFromCamera();
                                  } else if (source == 'gallery') {
                                    image = await _imagePickerService.pickFromGallery();
                                  }

                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    setDialogState(() {
                                      pickedImage = image;
                                      pickedImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppPallete.primaryOrange,
                                  size: 20,
                                ),
                                label: const Text(
                                  "Add Image",
                                  style: TextStyle(
                                    color: AppPallete.primaryOrange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppPallete.primaryOrange.withValues(alpha: 0.4)),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppPallete.divider),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppPallete.greyText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final title = titleController.text.trim().isEmpty
                                    ? "New Note"
                                    : titleController.text.trim();

                                final content = contentController.text.trim();

                                if (content.isEmpty) return;

                                Navigator.pop(
                                  context,
                                  AddEventResult(
                                    title: title,
                                    content: content,
                                    image: pickedImage,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPallete.primaryOrange,
                                foregroundColor: AppPallete.whiteColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Add",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }
}