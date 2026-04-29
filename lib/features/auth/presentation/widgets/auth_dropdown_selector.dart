import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class AuthDropdownSelector extends StatelessWidget {
  final List<String> items;
  final String hintText;
  final Function(String?) onChanged;
  final String? selectedValue;

  const AuthDropdownSelector({
    super.key,
    required this.items,
    required this.hintText,
    required this.onChanged,
    required this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(
          hintText,
          style: TextStyle(
            color: AppPallete.greyText.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: AppPallete.greyText,
        ),
        dropdownColor: AppPallete.cardBg,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.wc_outlined,
            color: AppPallete.greyText,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: AppPallete.whiteColor),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null) {
            return "Please select $hintText";
          }
          return null;
        },
      ),
    );
  }
}