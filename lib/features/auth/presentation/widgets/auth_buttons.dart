import 'package:flutter/material.dart';

class AuthButtons extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  const AuthButtons({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(fixedSize: const Size(400, 50)),
        child: Text(buttonText),
      ),
    );
  }
}
