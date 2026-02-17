import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:flutter/material.dart';

void main() {
  //hello
  runApp(const MyApp());
  //hello123
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SignUpPage(),
    );
  }
}
