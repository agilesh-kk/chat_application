import 'package:chat_application/core/common/widgets/nav_page.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/convo_page.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:chat_application/features/status/presentation/pages/status_page.dart';
import 'package:chat_application/features/watch2gether/presentation/pages/w2g_home_page.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthInitial || curr is AuthUnauthenticated || curr is AuthSuccess,
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          //return const _SplashScreen();
        }
        if (state is AuthSuccess) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => serviceLocator<ConversationBloc>(),
              ),
            ],
            child: NavigationPage(
              pages: [
                ConversationPage(userId: state.user.id),
                StatusPage(),
                const W2GHomePage(),
                ProfilePage(
                  isUser: true,
                ),
              ],
            ),
          );
        }
        return const SignInPage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              'Memento',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
