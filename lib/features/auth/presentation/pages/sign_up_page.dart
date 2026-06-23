import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_dropdown_selector.dart';
import 'package:chat_application/features/auth/presentation/widgets/auth_fields.dart';
import 'package:chat_application/core/utils/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? selectedDate;
  String? selectedGender;
  final formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
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
    _focusNode.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppPallete.darkBg,
        body: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          },
          child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if(state is AuthFailure){
                showSnackbar(context, state.message);
              } else if (state is AuthSuccess) {
                Navigator.of(context).popUntil((route) => route.isFirst);
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
                        const SizedBox(height: 60),
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildInputFields(),
                        const SizedBox(height: 16),
                        _buildDateAndGender(),
                        const SizedBox(height: 16),
                        _buildSignUpButton(),
                        const SizedBox(height: 24),
                        _buildSignInLink(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      ),
    ),
    ),
  );
  }


  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
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
            Icons.person_add_rounded,
            size: 36,
            color: AppPallete.primaryOrange,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppPallete.whiteColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join us and start connecting',
          style: TextStyle(
            fontSize: 14,
            color: AppPallete.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AuthFields(
            hinText: 'Full Name',
            textController: nameController,
            isObscure: false,
            icon: Icons.person_outline,
            isSmall : true,
          ),
          const SizedBox(height: 16),
          AuthFields(
            hinText: 'Email',
            textController: emailController,
            isObscure: false,
          ),
          const SizedBox(height: 16),
          AuthFields(
            hinText: 'Password',
            textController: passwordController,
            isObscure: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndGender() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          DatePicker(
            controller: birthDateController,
            hintText: "Birth Date",
            onDateSelected: (date) {
              selectedDate = date;
            },
          ),
          const SizedBox(height: 16),
          AuthDropdownSelector(
            items: const ['Male', 'Female', 'Other'],
            hintText: 'Gender',
            selectedValue: selectedGender,
            onChanged: (value) {
              setState(() {
                selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return AuthButtons(
      buttonText: "Create Account",
      onPressed: () {
        if (formKey.currentState!.validate() && selectedDate != null) {
          context.read<AuthBloc>().add(
                AuthSignUp(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  birthDate: selectedDate!,
                  gender: selectedGender!,
                ),
              );
        }
      },
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: AppPallete.greyText),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SignInPage(),
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
            'Sign In',
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