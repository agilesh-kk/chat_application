import 'package:flutter/material.dart';

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

  Future<void> pickDate() async {
    DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        widget.controller.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });

      if (widget.onDateSelected != null) {
        widget.onDateSelected!(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: pickDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select ${widget.hintText}";
        }
        return null;
      },
    );
  }
}