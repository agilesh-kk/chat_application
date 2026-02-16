import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),

        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign Up.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50, color: AppPallette.textColor),
              ),
          
              //authentication input fields for singup page
              SizedBox(height: 20),
              AuthFields(
                hinText: 'Name',
                textController: nameController,
                isObscure: false,
              ),
              SizedBox(height: 20),
              AuthFields(
                hinText: 'Phone Number',
                textController: phoneNumberController,
                isObscure: false,
              ),
              SizedBox(height: 20),

              AuthButtons(buttonText: "Sign up"),
            ],
          ),
        ),
      ),
    );
  }
}
