import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

// creating a reusable modal bottom sheet which has a list of selections and returns the selected value to the caller
class ModalBottomSheet extends StatelessWidget {
  final String title;
  final List<BottomSheetOption> options;
  final VoidCallback? onCancel;


  const ModalBottomSheet({
    super.key,
    required this.title,
    this.options = const [],
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((option) {
              return ListTile(
                leading: Icon(
                  option.icon,
                  color: AppPallete.primaryOrange,
                ),
                title: Text(
                  option.label,
                  style: const TextStyle(color: AppPallete.whiteColor),
                ),
                onTap: () {
                  Navigator.pop(context, option.value);
                },
              );
            }),
            ListTile(
              leading: const Icon(
                Icons.close,
                color: AppPallete.errorColor,
              ),
              title: const Text(
                "Cancel",
                style: TextStyle(color: AppPallete.whiteColor),
              ),
              onTap: () {
                Navigator.pop(context);
                onCancel?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    List<BottomSheetOption> options = const [],
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppPallete.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) => ModalBottomSheet(
        title: title,
        options: options,
        onCancel: onCancel,
      ),
    );
  }
}

class BottomSheetOption<T> {
  final T value;
  final String label;
  final IconData icon;

  BottomSheetOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}