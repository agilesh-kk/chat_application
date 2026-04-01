import 'package:flutter/material.dart';


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
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(hintText),
      items: items.map((String value){
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),

      onChanged: onChanged,

      validator: (value){
        if(value == null){
          return "Please select your gender";
        }
        return null;
      },
    );
  }
}