import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_options_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  final bool isUser;
  final dynamic user;
  const ProfilePage({
    super.key,
    required this.isUser,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;
    
    final profileUser = user ?? (appUserState is AppUserIsSignedin ? appUserState.user : null);

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),        
        actions: isUser ? [
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
        ] : null,
      ),
      body: profileUser == null ? const Center(child: Text("No user found")) :
           Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: profileUser.profilePic != null
                        ? AssetImage(profileUser.profilePic!)
                        : null,
                    child: profileUser.profilePic == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                ),

                SizedBox(height: 20,),

                Text(
                  profileUser.name,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500
                  ),
                ),

                SizedBox(height: 20,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: isUser ? [
                    UserOptionsRow(
                      icon: Icons.add_a_photo, 
                      label: "Edit avatar", 
                      onTap: (){
                        Navigator.push(
                          context, MaterialPageRoute(
                            builder: (_) => EditAvatar(
                              userId: profileUser.id,
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
                  ] : 
                  [
                    UserOptionsRow(
                      icon : Icons.message,
                      label : "Send message",
                      onTap : (){
                        if(appUserState is AppUserIsSignedin){
                          final currentuser = appUserState.user;
                          Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (c)=>ChatPage(
                              currentUserId: currentuser.id, 
                              receiverId: profileUser.id, 
                              receiverName: profileUser.name
                            )
                          )
                        );
                        }
                      },
                    ),
                  ],
                ),
                Text("Email: ${profileUser.email}"),
                Text("Birth date: ${DateFormat('dd MMM yyyy').format(profileUser.birthDate)}"),
              ],
            ),
          )
          //: const Text("No user signed in"),
    );
  }
}
