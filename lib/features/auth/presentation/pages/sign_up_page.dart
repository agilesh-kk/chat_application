import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:chat_application/features/chats/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose(){
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10),

        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            
            if(state is AuthFailure){
              showSnackbar(context, state.message);
            }
            else if(state is AuthSuccess){
              Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
            }
          },
          builder: (context, state) {
            if(state is AuthLoading){
              return const Loader();
            }
            return Form(
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
                  hinText: 'Email',
                  textController: emailController,
                  isObscure: false,
                ),
                SizedBox(height: 20),
                AuthFields(
                  hinText: 'Password',
                  textController: passwordController,
                  isObscure: true,
                ),
                SizedBox(height: 20),
          
                AuthButtons(
                  buttonText: "Sign up",
                  onPressed: (){
                    print("Form validated");
                    if(formKey.currentState!.validate()){
                      context.read<AuthBloc>().add(
                        AuthSignUp(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        ),
                      );
                    }
                  },
                ),
          
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
          );}
        ),
      ),
    );
  }
}
