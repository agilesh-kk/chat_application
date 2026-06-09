import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

//displays a snackbar at the bottom of the app
void showSnackbar (BuildContext context, String content){
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          content,
          style: TextStyle(color: AppPallete.whiteColor),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppPallete.primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
}