import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog(
    BuildContext context, String text, IconData icon) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppPallete.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppPallete.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPallete.primaryOrange.withValues(alpha: 0.2),
                      AppPallete.lightOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppPallete.primaryOrange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text,
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      context: context,
                      label: "No",
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton(
                      context: context,
                      label: "Yes",
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildButton({
  required BuildContext context,
  required String label,
  required bool isPrimary,
}) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(isPrimary),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  AppPallete.primaryOrange,
                  AppPallete.lightOrange,
                ],
              )
            : null,
        color: isPrimary ? null : AppPallete.darkTertiary,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary
            ? null
            : Border.all(color: AppPallete.divider),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary
                ? AppPallete.whiteColor
                : AppPallete.greyText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}