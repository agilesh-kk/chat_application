import 'package:flutter/material.dart';

class AuthFields extends StatefulWidget {
  final String hinText;
  final TextEditingController textController;
  final bool isObscure; //to store fields like passwords and confidential infos.

  const AuthFields({
    super.key,
    required this.hinText,
    required this.textController,
    required this.isObscure,
  });

  @override
  State<AuthFields> createState() => _AuthFieldsState();
}

class _AuthFieldsState extends State<AuthFields> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: widget.hinText,
        //creating the hide/unhide icon
        suffixIcon: widget.isObscure
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
      ),
      controller: widget.textController,
      obscureText: _isObscured,
      validator: (value) {
        if (value!.isEmpty) {
          return "${widget.hinText} is empty";
        }
        return null;
      },
    );
  }
}
