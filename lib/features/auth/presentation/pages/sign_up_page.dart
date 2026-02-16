import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose(){
    nameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

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

              SizedBox(height: 20),
              //to have duoble string in same line wiht different properties
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignInPage()));
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: Theme.of(context).textTheme.titleMedium, //refering to the theme of the app
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppPallette.textColor,
                          fontWeight: FontWeight.bold,
                        )
                      )
                    ]
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
