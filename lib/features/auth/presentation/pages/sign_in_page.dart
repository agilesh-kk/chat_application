import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                "Sign In.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50, color: AppPallette.textColor),
              ),
          
              //authentication input fields for singup page
              SizedBox(height: 20),
              AuthFields(
                hinText: 'Email',
                textController: emailController,
                isObscure: false,
              ),
              AuthFields(
                hinText: 'Password',
                textController: emailController,
                isObscure: false,
              ),
              SizedBox(height: 20),

              AuthButtons(buttonText: "Sign In",onPressed: (){},),

              SizedBox(height: 20),
              //to have duoble string in same line wiht different properties
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                },
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context).textTheme.titleMedium, //refering to the theme of the app
                    children: [
                      TextSpan(
                        text: 'Sign Up',
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