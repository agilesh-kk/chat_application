import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

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
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppPallete.primaryOrange,
            AppPallete.lightOrange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPallete.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          overlayColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}