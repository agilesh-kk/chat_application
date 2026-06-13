import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_details_card.dart';
import 'package:chat_application/features/timeline/presentation/pages/personal_timeline_page.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';

class ProfilePage extends StatefulWidget {
  final bool isUser;
  final dynamic user;
  final bool isEmbedded;
  final VoidCallback? onClose;
  const ProfilePage({
    super.key,
    required this.isUser,
    this.user,
    this.isEmbedded = false,
    this.onClose,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _appBarSlide;
  late Animation<Offset> _profileCardSlide;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _appBarSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _profileCardSlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;
    final profileUser =
        widget.user ?? (appUserState is AppUserIsSignedin ? appUserState.user : null);

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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _appBarSlide,
                            child: _buildAppBar(context, profileUser),
                          ),
                          const SizedBox(height: 32),
                          _buildWebLayout(context, profileUser),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic profileUser) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.isUser)
                GestureDetector(
                  onTap: () {
                    if (widget.isEmbedded) {
                      widget.onClose?.call();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppPallete.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPallete.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: AppPallete.whiteColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Back",
                          style: TextStyle(
                            color: AppPallete.whiteColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  "Profile",
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
              const Spacer(),
              if (widget.isUser)
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
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
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

  Widget _buildWebLayout(BuildContext context, dynamic profileUser) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideTransition(
          position: _profileCardSlide,
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                _buildProfileCard(context, profileUser),
                if (widget.isUser) ...[
                  const SizedBox(height: 24),
                  _buildTimelineCard(context, profileUser),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: SlideTransition(
            position: _contentSlide,
            child: _buildContentPanel(context, profileUser),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic profileUser) {
    final friendsState = context.watch<FriendsCubit>().state;
    final bool isOnline;
    if (!widget.isUser && friendsState is FriendsLoaded) {
      isOnline = friendsState.friends[profileUser.id]?.isEffectivelyOnline ?? false;
    } else {
      isOnline = true;
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(profileUser),
          const SizedBox(height: 32),
          Text(
            profileUser.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusBadge(profileUser, isOnline),
          const SizedBox(height: 32),
          UserDetailsCard(
            bio: profileUser.bio,
            onEditBio: widget.isUser ? () {} : null,
            userId: profileUser.id,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic profileUser) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPallete.primaryOrange.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundImage: profileImageProvider(profileUser.profilePic),
              backgroundColor: AppPallete.cardBg,
              child: profileUser.profilePic == null
                  ? Icon(Icons.person, size: 50, color: AppPallete.greyText)
                  : null,
            ),
          ),
          if (widget.isUser)
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAvatar(userId: profileUser.id),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPallete.darkBg, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: AppPallete.whiteColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic profileUser, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isOnline ? AppPallete.statusGreen : AppPallete.greyText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          if (profileUser.email != null) ...[
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: AppPallete.divider,
                shape: BoxShape.circle,
              ),
            ),
            Icon(Icons.email_outlined, size: 16, color: AppPallete.greyText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                profileUser.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPallete.greyText,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentPanel(BuildContext context, dynamic profileUser) {
    final friendsState = context.watch<FriendsCubit>().state;
    final appUserState = context.watch<AppUserCubit>().state;
    final currentUserId =
        appUserState is AppUserIsSignedin ? appUserState.user.id : null;

    if (widget.isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAboutCards(profileUser),
          const SizedBox(height: 32),
          if (friendsState is FriendsLoaded)
            _buildFriendsPanel(
              context,
              friendsState.friends.values.toList(),
              currentUserId,
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAboutCards(profileUser),
          const SizedBox(height: 32),
          _buildMessageButton(context, profileUser),
        ],
      );
    }
  }

  Widget _buildAboutCards(dynamic profileUser) {
    final infoItems = <_InfoItem>[
      _InfoItem(
        icon: Icons.email_outlined,
        label: "Email",
        value: profileUser.email ?? "-",
      ),
      _InfoItem(
        icon: Icons.cake_outlined,
        label: "Birth Date",
        value:
            profileUser.birthDate != null ? _formatDate(profileUser.birthDate) : "-",
      ),
      _InfoItem(
        icon: profileUser.gender != null &&
                profileUser.gender.toLowerCase() == 'male'
            ? Icons.male
            : profileUser.gender != null &&
                    profileUser.gender.toLowerCase() == 'female'
                ? Icons.female
                : Icons.person_outline,
        label: "Gender",
        value: profileUser.gender ?? "-",
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: List.generate(infoItems.length, (i) {
          final item = infoItems[i];
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.icon,
                      size: 28,
                      color: AppPallete.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppPallete.greyText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.whiteColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < infoItems.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    height: 1,
                    color: AppPallete.divider.withValues(alpha: 0.5),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildTimelineCard(BuildContext context, dynamic profileUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPallete.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite,
              size: 28,
              color: AppPallete.primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Personal Timeline",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "View posts and activity",
            style: TextStyle(
              fontSize: 13,
              color: AppPallete.greyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PersonalTimeLinePage(userId: profileUser.id),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new,
                      size: 18, color: AppPallete.whiteColor),
                  SizedBox(width: 8),
                  Text(
                    "View Timeline",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.whiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsPanel(
    BuildContext context,
    List<FriendModel> friends,
    String? currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline,
                  size: 20, color: AppPallete.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                "Friends",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.whiteColor,
                ),
              ),
              const Spacer(),
              Text(
                "${friends.length}",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppPallete.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No friends yet",
                  style: TextStyle(fontSize: 14, color: AppPallete.greyText),
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: friends.map((friend) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          isUser: false,
                          user: friend,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AppPallete.primaryOrange
                                      .withValues(alpha: 0.6),
                                  AppPallete.lightOrange
                                      .withValues(alpha: 0.3),
                                  AppPallete.primaryOrange
                                      .withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppPallete.cardBg,
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    friend.profilePic.isNotEmpty
                                        ? profileImageProvider(
                                            friend.profilePic)
                                        : null,
                                backgroundColor: AppPallete.cardBg,
                                child: friend.profilePic.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: AppPallete.greyText,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: friend.isEffectivelyOnline
                                    ? AppPallete.statusGreen
                                    : AppPallete.greyText,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppPallete.cardBg,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPallete.whiteColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageButton(BuildContext context, dynamic profileUser) {
    return GestureDetector(
      onTap: () {
        if (widget.isEmbedded) {
          widget.onClose?.call();
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
            const Icon(
              Icons.chat_bubble_outline,
              color: AppPallete.whiteColor,
              size: 28,
            ),
            const SizedBox(width: 14),
            const Text(
              "Send Message",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
