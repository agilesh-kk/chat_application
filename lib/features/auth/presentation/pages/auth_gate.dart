import 'package:chat_application/core/common/widgets/Nav_page.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/landing/presentation/pages/landing_page.dart';
import 'package:chat_application/features/chats/presentation/pages/home_page.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:chat_application/features/status/presentation/pages/status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev,curr) => curr is AuthUnauthenticated || curr is AuthSuccess,
      builder: (context, state) {
        if(state is AuthSuccess){
          return NavigationPage(
            pages: [
              HomePage(userId: state.user.id),
              StatusPage(),
              ProfilePage(
                isUser: true,
                //user: state.user,
              ),
            ]
          );
        }
        return const LandingPage();
      },
    );
  }
}