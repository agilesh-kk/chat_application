import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/profile_pic_provider.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/achievement/presentation/pages/achievement_page.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/presentation/pages/friends_page.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_details_card.dart';
import 'package:chat_application/features/timeline/presentation/pages/personal_timeline_page.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';

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
      backgroundColor: AppPallete.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPallete.darkBg,
              AppPallete.darkSecondary,
              AppPallete.darkBg,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: profileUser == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: AppPallete.greyText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No user found",
                        style: TextStyle(
                          color: AppPallete.greyText,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildAppBar(context),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHeader(context, profileUser),
                      ),
                      SliverToBoxAdapter(
                        child: _buildStatsRow(context, appUserState, profileUser),
                      ),
                      SliverToBoxAdapter(
                        child: _buildMoreActions(context, profileUser, appUserState),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isUser)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPallete.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPallete.divider),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppPallete.whiteColor,
                  size: 20,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Profile",
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 12,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppPallete.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (isUser)
            _buildActionButton(
              icon: Icons.logout_rounded,
              onTap: () async {
                final shouldLogout = await showConfirmationDialog(
                  context,
                  'Log out?',
                  Icons.warning_amber_outlined,
                );
                if (shouldLogout == true && context.mounted) {
                  context.read<AuthBloc>().add(AuthSignOut());
                  await FlutterShortcut.clearShortcutItems();
                }
              },
              color: AppPallete.errorColor,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              icon,
              color: color ?? AppPallete.whiteColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profileUser) {
    final friendsState = context.watch<FriendsCubit>().state;
    final bool isOnline;
    if (!isUser && friendsState is FriendsLoaded) {
      isOnline = friendsState.friends[profileUser.id]?.isEffectivelyOnline ?? false;
    } else {
      isOnline = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppPallete.primaryOrange.withValues(alpha: 0.8),
                      AppPallete.lightOrange.withValues(alpha: 0.4),
                      AppPallete.primaryOrange.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppPallete.primaryOrange.withValues(alpha: 0.5),
                      AppPallete.darkBg.withValues(alpha: 0.8),
                    ],
                  ),
                  border: Border.all(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (profileUser.profilePic != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileImageViewer(
                          imageProvider: ProfilePicProvider.resolve(profileUser.profilePic, userId: profileUser.id),
                          heroTag: 'profile_${profileUser.id}',
                        ),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 68,
                  backgroundImage: profileUser.profilePic != null
                      ? ProfilePicProvider.resolve(profileUser.profilePic, userId: profileUser.id)
                      : null,
                  backgroundColor: AppPallete.cardBg,
                  child: profileUser.profilePic == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: AppPallete.greyText,
                        )
                      : null,
                ),
              ),
              if (isUser)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAvatar(userId: profileUser.id,pfpUrl: profileUser.profilePic,),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppPallete.darkBg,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPallete.primaryOrange
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            profileUser.name,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppPallete.cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppPallete.divider.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppPallete.statusGreen
                        : AppPallete.greyText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: AppPallete.greyText,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    profileUser.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppPallete.greyText,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic appUserState, dynamic profileUser) {
    final friends = context.watch<FriendsCubit>().state;
    var friendsCount = 0;
    
    if(friends is FriendsLoaded){
      friendsCount = friends.friends.length;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPallete.cardBg,
              AppPallete.darkTertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppPallete.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (isUser) ...[
                  _buildStatItem(
                    icon: Icons.people_outline,
                    value: friendsCount.toString(),
                    label: "Friends",
                    color: AppPallete.primaryOrange,
                    isClickable: isUser,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FriendsPage(),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppPallete.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
                _buildStatItem(
                  icon: Icons.cake_outlined,
                  value: profileUser.birthDate != null ? _formatDate(profileUser.birthDate) : "",
                  label: "Born",
                  color: AppPallete.lightOrange,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppPallete.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildStatItem(
                  icon: profileUser.gender != null && profileUser.gender.toLowerCase() == 'male'
                      ? Icons.male
                      : profileUser.gender != null && profileUser.gender.toLowerCase() == 'female'
                          ? Icons.female
                          : Icons.person_outline,
                  value: profileUser.gender ?? "",
                  label: "Gender",
                  color: AppPallete.primaryOrange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppPallete.divider.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            UserDetailsCard(
              bio: profileUser.bio,
              onEditBio: isUser ? () {} : null,
              userId: profileUser.id,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppPallete.whiteColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppPallete.greyText,
          ),
        ),
      ],
    );

    if (isClickable && onTap != null) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Expanded(child: content);
  }

  Widget _buildMoreActions(
      BuildContext context, dynamic profileUser, dynamic appUserState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Explore",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.whiteColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isUser)
            Row(
              children: [
                // Expanded(
                //   child: _buildFeatureCard(
                //     icon: Icons.emoji_events,
                //     title: "Achievements",
                //     subtitle: "Your badges & rewards",
                //     gradientColors: [
                //       AppPallete.storyGradientStart,
                //       AppPallete.storyGradientEnd,
                //     ],
                //     onTap: () {
                //       Navigator.push(
                //         context, 
                //         MaterialPageRoute(builder: (context) => AchievementPage(userId: profileUser.id) )
                //       );
                //     },
                //   ),
                // ),
                // const SizedBox(width: 14),
                Expanded(
                  child: _buildFeatureCard(
                    icon: Icons.favorite,
                    title: "Timeline",
                    subtitle: "Activity history",
                    gradientColors: [
                      AppPallete.primaryOrange,
                      AppPallete.lightOrange,
                    ],
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => PersonalTimeLinePage(userId: profileUser.id) )
                      );
                    },
                  ),
                ),
              ],
            )
          else
            _buildMessageButton(context, profileUser, appUserState),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.9),
              gradientColors[1].withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageButton(
      BuildContext context, dynamic profileUser, dynamic appUserState) {
    return GestureDetector(
      onTap: () {
        if (appUserState is AppUserIsSignedin) {
          final currentuser = appUserState.user;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ChatPage(
                currentUserId: currentuser.id,
                receiverId: profileUser.id,
                receiverName: profileUser.name,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPallete.primaryOrange,
              AppPallete.lightOrange,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppPallete.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: AppPallete.whiteColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Send Message",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

}