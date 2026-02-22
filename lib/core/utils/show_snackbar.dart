import 'package:flutter/material.dart';

//displays a snackbar at the bottom of the app
void showSnackbar (BuildContext context, String content){
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(content),
      )
    );
}