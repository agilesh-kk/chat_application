import 'package:chat_application/core/common/widgets/Nav_page.dart';
import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/presentation/pages/convo_page.dart';
import 'package:chat_application/features/chats/presentation/pages/search_page.dart';
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
        if(state is AuthLoading||state is AuthInitial){
          return const Scaffold(
            body: Center(child: Loader(),),
          );
        }
        //print(state);
        if(state is AuthSuccess){
          return NavigationPage(pages: [ConversationPage(userId: state.user.id)]);
        }
        return const SignInPage();
      },
    );
  }
}