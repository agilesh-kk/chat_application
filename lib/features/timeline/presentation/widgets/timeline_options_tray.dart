import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class TimelineOptionsTray {
  static Future<void> show({
    required BuildContext context,
    Offset? position,
    required VoidCallback onDelete,
  }) async {
    final pos = position ?? MediaQuery.of(context).size.center(Offset.zero);
    final selected = await showMenu(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppPallete.cardBg,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy,
        pos.dx,
        pos.dy,
      ),
      items: [
        const PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text("Delete from timeline"),
            ],
          ),
        ),
      ],
    );

    if (selected == "delete") {
      showDeleteConfirmDialog(context: context, onDelete: onDelete);
    }
  }

  static void showDeleteConfirmDialog({
    required BuildContext context,
    required VoidCallback onDelete,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPallete.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPallete.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppPallete.errorColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppPallete.errorColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Remove Memory',
                          style: TextStyle(
                            color: AppPallete.whiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will remove it from your timeline permanently.',
                      style: TextStyle(
                        color: AppPallete.greyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildButton(
                          label: 'Cancel',
                          onTap: () => Navigator.of(ctx).pop(),
                          isPrimary: false,
                          context: context,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildButton(
                            label: 'Delete',
                            onTap: () {
                              Navigator.of(ctx).pop();
                              onDelete();
                            },
                            isPrimary: true,
                            isDestructive: true,
                            context: context,
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
  }

  static Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDestructive
                  ? AppPallete.errorColor
                  : AppPallete.primaryOrange)
              : AppPallete.darkTertiary,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: AppPallete.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary
                ? AppPallete.whiteColor
                : (isDestructive
                    ? AppPallete.errorColor
                    : AppPallete.greyText),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
