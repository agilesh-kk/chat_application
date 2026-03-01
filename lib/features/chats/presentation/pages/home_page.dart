import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AppUserCubit>().state;
    if (state is AppUserIsSignedin) {
      //context.read<BlogBloc>().add(YourBlogsEvent(posterId: state.user.id));
      //context.read<BlogBloc>().add(GetAllBlogsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // The three dots icon
            onSelected: (value) async {
              if (value == 'logout') {
                // Trigger the logout event in your Bloc
                final shouldLogout = await showConfirmationDialog(
                  context,
                  'Log out?',
                  Icons.warning_amber_outlined,
                );
                if (shouldLogout == true && context.mounted) {
                  context.read<AuthBloc>().add(AuthSignOut());
                }
                //context.read<AuthBloc>().add(AuthUserSignOut());
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child:
            appUserState is AppUserIsSignedin
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Name: ${appUserState.user.name}"),
                    Text("Email: ${appUserState.user.email}"),
                  ],
                )
                : const Text("No user signed in"),
      ),
    );
  }
}
