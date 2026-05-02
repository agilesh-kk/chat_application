import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if(state is AuthFailure){
                showSnackbar(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppPallete.primaryOrange,
                  ),
                );
              }
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 120),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildInputFields(),
                      const SizedBox(height: 16),
                      _buildForgotPassword(),
                      const SizedBox(height: 16),
                      _buildSignInButton(),
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildSocialButtons(),
                      const SizedBox(height: 24),
                      _buildSignUpLink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPallete.primaryOrange.withValues(alpha: 0.2),
                AppPallete.lightOrange.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: AppPallete.primaryOrange.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 32,
            color: AppPallete.primaryOrange,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppPallete.whiteColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter credentials to continue',
          style: TextStyle(
            fontSize: 13,
            color: AppPallete.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AuthFields(
            hinText: 'Email',
            textController: emailController,
            isObscure: false,
          ),
          const SizedBox(height: 12),
          AuthFields(
            hinText: 'Password',
            textController: passwordController,
            isObscure: true,
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppPallete.primaryOrange,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return AuthButtons(
      buttonText: "Sign In",
      onPressed: () {
        if (formKey.currentState!.validate()) {
          context.read<AuthBloc>().add(
                AuthSignIn(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                ),
              );
        }
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppPallete.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(color: AppPallete.greyText, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AppPallete.divider)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(Icons.g_mobiledata_rounded, 'Google'),
        const SizedBox(width: 16),
        _buildSocialButton(Icons.apple_rounded, 'Apple'),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppPallete.whiteColor, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppPallete.whiteColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: AppPallete.greyText),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SignUpPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 150),
              ),
            );
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppPallete.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}