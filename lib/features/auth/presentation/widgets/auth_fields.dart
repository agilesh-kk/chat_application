import 'package:flutter/material.dart';

class AuthFields extends StatelessWidget {
  final String hinText;
  final TextEditingController textController;
  final bool isObscure; //to store fields like passwords and confidential infos.

  const AuthFields({
    super.key,
    required this.hinText,
    required this.textController, required this.isObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hinText
      ),
      controller: textController,
      obscureText: isObscure,

      validator: (value){
        if(value!.isEmpty){
          return "$hinText is empty";
        }
        return null;
      },
    );
  }
}
