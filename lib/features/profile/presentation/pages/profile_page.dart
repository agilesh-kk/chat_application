import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/profile_pic_provider.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/achievement/presentation/pages/achievement_page.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/friends/presentation/friend_requests_cubit.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/friends/presentation/pages/friend_requests_page.dart';
import 'package:chat_application/features/profile/presentation/pages/friends_page.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_details_card.dart';
import 'package:chat_application/features/timeline/presentation/pages/personal_timeline_page.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';

class ProfilePage extends StatefulWidget {
  final bool isUser;
  final dynamic user;
  const ProfilePage({super.key, required this.isUser, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    if (widget.isUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appUserState = context.read<AppUserCubit>().state;
        if (appUserState is AppUserIsSignedin) {
          context
              .read<FriendRequestsCubit>()
              .loadFriendRequests(userId: appUserState.user.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    final profileUser = widget.user ??
        (appUserState is AppUserIsSignedin ? appUserState.user : null);

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
              : BlocListener<FriendRequestsCubit, FriendRequestsState>(
                  listener: (context, state) {
                    if (state is FriendRequestAccepted) {
                      showSnackbar(context, "Friend request accepted!");
                    } else if (state is FriendRequestRejected) {
                      showSnackbar(context, "Friend request declined");
                    }
                  },
                  child: BlocListener<BioBloc, BioState>(
                  listener: (context, state) {
                    if (state is BioUpdateSuccess) {
                      final appUserState = context.read<AppUserCubit>().state;
                      if (appUserState is AppUserIsSignedin) {
                        final updatedUser = appUserState.user.copyWith(
                          bio: state.bio,
                        );
                        context.read<AppUserCubit>().updateUser(updatedUser);
                      }
                      showSnackbar(context, "Bio updated successfully");
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
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isUser)
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
          if (widget.isUser)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFriendRequestsBadgeButton(context),
                const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildFriendRequestsBadgeButton(BuildContext context) {
    return BlocBuilder<FriendRequestsCubit, FriendRequestsState>(
      builder: (context, state) {
        final count = state is FriendRequestsLoaded ? state.requests.length : 0;
        final hasBadge = count > 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: hasBadge
                  ? LinearGradient(
                      colors: [
                        AppPallete.primaryOrange,
                        AppPallete.lightOrange,
                      ],
                    )
                  : null,
              color: hasBadge ? null : AppPallete.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasBadge
                    ? AppPallete.primaryOrange.withValues(alpha: 0.5)
                    : AppPallete.divider,
              ),
              boxShadow: hasBadge
                  ? [
                      BoxShadow(
                        color:
                            AppPallete.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
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
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: hasBadge
                            ? AppPallete.whiteColor
                            : AppPallete.whiteColor,
                        size: 24,
                      ),
                      if (hasBadge)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppPallete.errorColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppPallete.cardBg,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPallete.errorColor
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(
                                color: AppPallete.whiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    if (!widget.isUser && friendsState is FriendsLoaded) {
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
              if (widget.isUser)
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
                if (widget.isUser) ...[
                  _buildStatItem(
                    icon: Icons.people_outline,
                    value: friendsCount.toString(),
                    label: "Friends",
                    color: AppPallete.primaryOrange,
                    isClickable: widget.isUser,
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
              onEditBio: widget.isUser ? () {} : null,
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
    final friendsState = context.watch<FriendsCubit>().state;
    context.watch<FriendRequestsCubit>();
    final currentUser = appUserState is AppUserIsSignedin ? appUserState.user : null;

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
                widget.isUser ? "Explore" : "Actions",
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
          if (widget.isUser)
            Row(
              children: [
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
            _buildActionSection(context, profileUser, currentUser, friendsState),
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
    FriendsState friendsState,
  ) {
    if (currentUser == null) return const SizedBox();

    final isFriend = friendsState is FriendsLoaded &&
        friendsState.friends.containsKey(profileUser?.id);
    final isIncomingRequest = currentUser.requests != null &&
        currentUser.requests!.contains(profileUser?.id);

    if (isFriend) {
      return _buildFriendActionsRow(context, profileUser, currentUser);
    }

    if (isIncomingRequest) {
      return _buildAcceptRejectRow(context, profileUser, currentUser);
    }

    final cubit = context.read<FriendRequestsCubit>();

    return FutureBuilder<bool>(
      future: cubit.checkSentRequestStatus(
        currentUser.id,
        profileUser?.id ?? '',
      ),
      initialData: cubit.hasSentRequestTo(profileUser?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return _buildRequestSentDisplay(profileUser, currentUser, context);
        }
        return _buildAddFriendButton(context, profileUser, currentUser);
      },
    );
  }

  Widget _buildAcceptRejectRow(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<FriendRequestsCubit>().acceptFriendRequest(
                    userId: currentUser.id,
                    requesterId: profileUser.id,
                  );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppPallete.statusGreen,
                    AppPallete.statusGreen.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.statusGreen.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: AppPallete.whiteColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Accept",
                    style: TextStyle(
                      color: AppPallete.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<FriendRequestsCubit>().rejectFriendRequest(
                    userId: currentUser.id,
                    requesterId: profileUser.id,
                  );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppPallete.errorColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: AppPallete.errorColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Decline",
                    style: TextStyle(
                      color: AppPallete.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFriendButton(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<FriendRequestsCubit>().sendFriendRequest(
              userId: currentUser.id,
              friendId: profileUser.id,
            );
        showSnackbar(context, "Friend request sent!");
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
              Icons.person_add_outlined,
              color: AppPallete.whiteColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Add Friend",
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

  Widget _buildFriendActionsRow(
      BuildContext context, dynamic profileUser, dynamic currentUser) {
    return Row(
      children: [
        Expanded(
          child: _buildMessageButton(context, profileUser, currentUser),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRemoveFriendButton(context, profileUser, currentUser),
        ),
      ],
    );
  }

  Widget _buildRemoveFriendButton(
      BuildContext context, dynamic profileUser, dynamic currentUser) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppPallete.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Remove Friend',
              style: TextStyle(color: AppPallete.whiteColor),
            ),
            content: Text(
              'Remove ${profileUser.name} from your friends?',
              style: TextStyle(color: AppPallete.greyText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(color: AppPallete.greyText)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Remove',
                    style: TextStyle(color: AppPallete.errorColor)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.read<FriendsCubit>().removeFriend(
                userId: currentUser.id,
                friendId: profileUser.id,
              );
          showSnackbar(context, '${profileUser.name} removed from friends');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPallete.errorColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_remove_outlined,
              color: AppPallete.errorColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Remove Friend",
              style: TextStyle(
                color: AppPallete.errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelRequestDialog(BuildContext context, dynamic profileUser, dynamic currentUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.cardBg,
        title: Text(
          "Cancel Request",
          style: TextStyle(color: AppPallete.whiteColor),
        ),
        content: Text(
          "Cancel friend request to ${profileUser?.name ?? 'this user'}?",
          style: TextStyle(color: AppPallete.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "No",
              style: TextStyle(color: AppPallete.greyText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FriendRequestsCubit>().cancelFriendRequest(
                    userId: currentUser.id,
                    friendId: profileUser?.id ?? '',
                  );
            },
            child: Text(
              "Yes, Cancel",
              style: TextStyle(color: AppPallete.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSentDisplay(dynamic profileUser, dynamic currentUser, BuildContext context) {
    return GestureDetector(
      onTap: () => _showCancelRequestDialog(context, profileUser, currentUser),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPallete.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppPallete.greyText,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Request Sent",
              style: TextStyle(
                color: AppPallete.greyText,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageButton(
      BuildContext context, dynamic profileUser, dynamic currentUser) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ChatPage(
              currentUserId: currentUser.id,
              receiverId: profileUser.id,
              receiverName: profileUser.name,
            ),
          ),
        );
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