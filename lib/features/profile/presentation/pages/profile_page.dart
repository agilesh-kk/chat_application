import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_options_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  final bool isUser;
  //final User user;
  const ProfilePage({
    super.key,
    required this.isUser,
    //required this.user
  });

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),        
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // The three dots icon
            onSelected: (value) async {
              if (value == 'logout') {
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
      body: appUserState is AppUserIsSignedin
          ? Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: appUserState.user.profilePic != null
                        ? AssetImage(appUserState.user.profilePic!)
                        : null,
                    child: appUserState.user.profilePic == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                ),
                SizedBox(height: 20,),
                Text(
                  appUserState.user.name,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500
                  ),
                ),

                SizedBox(height: 20,),

                Row(
                  spacing: double.minPositive,
                  children: [
                    UserOptionsRow(
                      icon: Icons.add_a_photo, 
                      label: "Edit avatar", 
                      onTap: (){
                        Navigator.push(
                          context, MaterialPageRoute(
                            builder: (_) => EditAvatar(
                              userId: appUserState.user.id,
                            )
                          )
                        );
                      }
                    ),
                    UserOptionsRow(
                      icon: Icons.emoji_events, 
                      label: "Achievements", 
                      onTap: (){}
                    ),
                    UserOptionsRow(
                      icon: Icons.favorite, 
                      label: "Personal timeline", 
                      onTap: (){}
                    ),
                  ],
                ),
                Text("Email: ${appUserState.user.email}"),
                Text("Birth date: ${DateFormat('dd MMM yyyy').format(appUserState.user.birthDate)}"),
              ],
            ),
          )
          : const Text("No user signed in"),
    );
  }
}
