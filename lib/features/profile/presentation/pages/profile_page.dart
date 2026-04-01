import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_details_card.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_options_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  final bool isUser;
  final dynamic user;
  const ProfilePage({super.key, required this.isUser, this.user});

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    final profileUser =
        user ?? (appUserState is AppUserIsSignedin ? appUserState.user : null);

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),

        actions:
            isUser
                ? [
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
                ]
                : null,
      ),
      body:
          profileUser == null
              ? const Center(child: Text("No user found"))
              : BlocListener<BioBloc, BioState>(
                listener: (context, state) {
                  if (state is BioUpdateSuccess) {
                    final appUserState = context.read<AppUserCubit>().state;

                    if (appUserState is AppUserIsSignedin) {
                      final updatedUser = appUserState.user.copyWith(
                        bio: state.bio,
                      );

                      context.read<AppUserCubit>().updateUser(updatedUser);
                    }
                  }
                },
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage:
                              profileUser.profilePic != null
                                  ? AssetImage(profileUser.profilePic!)
                                  : null,
                          child:
                              profileUser.profilePic == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                    
                        SizedBox(height: 20),
                    
                        Text(
                          profileUser.name,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    
                        SizedBox(height: 20),
                    
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              //for user profile
                              isUser
                                  ? [
                                    //for editing the profile avatar
                                    UserOptionsRow(
                                      icon: Icons.add_a_photo,
                                      label: "Edit avatar",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => EditAvatar(
                                                  userId: profileUser.id,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                    
                                    //to view achievements
                                    UserOptionsRow(
                                      icon: Icons.emoji_events,
                                      label: "Achievements",
                                      onTap: () {},
                                    ),
                    
                                    //to view the personal timeline
                                    UserOptionsRow(
                                      icon: Icons.favorite,
                                      label: "Personal timeline",
                                      onTap: () {},
                                    ),
                                  ]
                                  :
                                  //for freinds profile
                                  [
                                    //to send message
                                    UserOptionsRow(
                                      icon: Icons.message,
                                      label: "Send message",
                                      onTap: () {
                                        if (appUserState is AppUserIsSignedin) {
                                          final currentuser = appUserState.user;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (c) => ChatPage(
                                                    currentUserId:
                                                        currentuser.id,
                                                    receiverId: profileUser.id,
                                                    receiverName:
                                                        profileUser.name,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                        ),
                        SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UserDetailsCard(
                              email: profileUser.email,
                              bio: profileUser.bio,
                              //button: isUser ? Icons.edit : null,
                              onEditBio:
                                  isUser
                                      ? () {
                                        // showEditBioBottomSheet(
                                        //   context: context,
                                        //   currentBio: profileUser.bio,
                                        //   userId: profileUser.id,
                                        // );
                                      }
                                      : null,
                              userId: profileUser.id,
                              birthDate: profileUser.birthDate,
                              gender: profileUser.gender,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      //: const Text("No user signed in"),
    );
  }
}
