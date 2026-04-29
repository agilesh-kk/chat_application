import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class DatePicker extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(DateTime)? onDateSelected;

  const DatePicker({
    super.key,
    required this.controller,
    required this.hintText,
    this.onDateSelected,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? selectedDate;
  bool _isFocused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final DateTime now = DateTime.now();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppPallete.primaryOrange,
              onPrimary: Colors.white,
              surface: AppPallete.cardBg,
              onSurface: AppPallete.whiteColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        widget.controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? AppPallete.inputBg : AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? AppPallete.primaryOrange.withValues(alpha: 0.5) 
              : AppPallete.divider.withValues(alpha: 0.3),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        readOnly: true,
        style: const TextStyle(color: AppPallete.whiteColor),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppPallete.greyText.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.cake_outlined,
            color: AppPallete.greyText,
            size: 20,
          ),
          suffixIcon: Icon(
            Icons.calendar_today,
            color: _isFocused ? AppPallete.primaryOrange : AppPallete.greyText,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        onTap: pickDate,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please select ${widget.hintText}";
          }
          return null;
        },
      ),
    );
  }
}