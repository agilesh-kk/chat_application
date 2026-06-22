import 'dart:ui';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/cubit/nav_page_index_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/friends/presentation/friend_requests_cubit.dart';
import 'package:chat_application/features/friends/presentation/pages/friend_requests_page.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/edit_avatar.dart';
import 'package:chat_application/features/profile/presentation/widgets/user_details_card.dart';
import 'package:chat_application/features/timeline/presentation/pages/personal_timeline_page.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_image_viewer.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _appBarSlide;
  late Animation<Offset> _profileCardSlide;
  late Animation<Offset> _contentSlide;
  late AnimationController _avatarAnimController;
  late Animation<double> _avatarFadeAnimation;
  late Animation<double> _avatarScaleAnimation;
  late AnimationController _personalTimelineAnimController;
  late Animation<double> _personalTimelineFadeAnimation;
  late Animation<double> _personalTimelineScaleAnimation;
  dynamic _selectedFriend;
  bool _showEditAvatar = false;
  bool _showPersonalTimeline = false;
  final FocusNode _profileFocusNode = FocusNode();
  final FocusNode _avatarFocusNode = FocusNode();
  final FocusNode _personalTimelineFocusNode = FocusNode();
  final FocusNode _profileBackFocusNode = FocusNode();

  void _closeFriendProfile() {
    setState(() => _selectedFriend = null);
  }

  void _openEditAvatar() {
    setState(() => _showEditAvatar = true);
    _avatarAnimController.forward(from: 0);
  }

  void _closeEditAvatar() {
    setState(() => _showEditAvatar = false);
  }

  void _openPersonalTimeline() {
    setState(() => _showPersonalTimeline = true);
    _personalTimelineAnimController.forward(from: 0);
  }

  void _closePersonalTimeline() {
    setState(() => _showPersonalTimeline = false);
  }

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

    _avatarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _avatarFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.easeOut,
      ),
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _personalTimelineAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _personalTimelineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _personalTimelineAnimController,
        curve: Curves.easeOut,
      ),
    );
    _personalTimelineScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _personalTimelineAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _avatarAnimController.dispose();
    _personalTimelineAnimController.dispose();
    _profileFocusNode.dispose();
    _avatarFocusNode.dispose();
    _personalTimelineFocusNode.dispose();
    _profileBackFocusNode.dispose();
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
          child: KeyboardListener(
            focusNode: _profileBackFocusNode,
            autofocus: !widget.isUser,
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape &&
                  !widget.isUser) {
                if (widget.isEmbedded) {
                  widget.onClose?.call();
                } else {
                  Navigator.pop(context);
                }
              }
            },
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
              : Stack(
                  children: [
                    BlocListener<BioBloc, BioState>(
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
                    if (_selectedFriend != null)
                      Positioned.fill(
                        child: KeyboardListener(
                          focusNode: _profileFocusNode,
                          autofocus: true,
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _closeFriendProfile();
                            }
                          },
                          child: ProfilePage(
                            isUser: false,
                            user: _selectedFriend,
                            isEmbedded: true,
                            onClose: _closeFriendProfile,
                          ),
                        ),
                      ),
                    if (_showEditAvatar)
                      Positioned.fill(
                        child: KeyboardListener(
                          focusNode: _avatarFocusNode,
                          autofocus: true,
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _closeEditAvatar();
                            }
                          },
                          child: Stack(
                            children: [
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Center(
                                child: AnimatedBuilder(
                                  animation: _avatarAnimController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _avatarFadeAnimation.value,
                                      child: Transform.scale(
                                        scale: _avatarScaleAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 480,
                                      maxHeight: 620,
                                    ),
                                    margin: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppPallete.cardBg,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppPallete.divider,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 40,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: EditAvatarContent(
                                      userId: profileUser.id,
                                      onClose: _closeEditAvatar,
                                      pfpUrl: profileUser.profilePic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showPersonalTimeline)
                      Positioned.fill(
                        child: KeyboardListener(
                          focusNode: _personalTimelineFocusNode,
                          autofocus: true,
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _closePersonalTimeline();
                            }
                          },
                          child: Stack(
                            children: [
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Center(
                                child: AnimatedBuilder(
                                  animation: _personalTimelineAnimController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _personalTimelineFadeAnimation.value,
                                      child: Transform.scale(
                                        scale: _personalTimelineScaleAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 520,
                                      maxHeight: 700,
                                    ),
                                    margin: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppPallete.cardBg,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppPallete.divider,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 40,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: PersonalTimelineContent(
                                      userId: profileUser.id,
                                      onClose: _closePersonalTimeline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
              if (widget.isUser) ...[
                _buildFriendRequestButton(context),
                const SizedBox(width: 12),
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

  Widget _buildFriendRequestButton(BuildContext context) {
    final reqState = context.watch<FriendRequestsCubit>().state;
    final pendingCount = reqState is FriendRequestsLoaded ? reqState.requests.length : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
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
            child: Icon(
              Icons.person_add_outlined,
              color: AppPallete.whiteColor,
              size: 24,
            ),
          ),
          if (pendingCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppPallete.errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.errorColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  "$pendingCount",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context, dynamic profileUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _buildHorizontalLayout(context, profileUser);
        }
        return _buildVerticalLayout(context, profileUser);
      },
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, dynamic profileUser) {
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

  Widget _buildVerticalLayout(BuildContext context, dynamic profileUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlideTransition(
          position: _profileCardSlide,
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
        const SizedBox(height: 32),
        SlideTransition(
          position: _contentSlide,
          child: _buildContentPanel(context, profileUser),
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
            child: GestureDetector(
              onTap: () {
                if (profileUser.profilePic != null) {
                  final provider = profileImageProvider(profileUser.profilePic)!;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileImageViewer(
                        imageProvider: provider,
                        heroTag: 'profile_${profileUser.id}',
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 55,
                backgroundImage: profileImageProvider(profileUser.profilePic),
                backgroundColor: AppPallete.cardBg,
                child: profileUser.profilePic == null
                    ? Icon(Icons.person, size: 50, color: AppPallete.greyText)
                    : null,
              ),
            ),
          ),
          if (widget.isUser)
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => _openEditAvatar(),
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
          _buildActionSection(context, profileUser, appUserState, friendsState),
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
            onTap: () => _openPersonalTimeline(),
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
                      setState(() => _selectedFriend = friend);
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

  Widget _buildActionSection(
    BuildContext context,
    dynamic profileUser,
    dynamic appUserState,
    FriendsState friendsState,
  ) {
    final currentUser = appUserState is AppUserIsSignedin ? appUserState.user : null;
    if (currentUser == null) return const SizedBox();

    final isFriend = friendsState is FriendsLoaded &&
        friendsState.friends.containsKey(profileUser?.id);
    final friendReqState = context.watch<FriendRequestsCubit>().state;
    final isIncomingRequest = friendReqState is FriendRequestsLoaded &&
        friendReqState.requests.containsKey(profileUser?.id);

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
          return _buildRequestSentDisplay(context, profileUser, currentUser);
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
              showSnackbar(context, "Friend request accepted!");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                  Icon(Icons.check, color: AppPallete.whiteColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Accept",
                    style: TextStyle(
                      color: AppPallete.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
              showSnackbar(context, "Friend request declined");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppPallete.errorColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: AppPallete.errorColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Decline",
                    style: TextStyle(
                      color: AppPallete.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
            Icon(
              Icons.person_add_outlined,
              color: AppPallete.whiteColor,
              size: 28,
            ),
            const SizedBox(width: 14),
            Text(
              "Add Friend",
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

  Widget _buildFriendActionsRow(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildFriendMessageButton(context, profileUser, currentUser),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRemoveFriendButton(context, profileUser, currentUser),
        ),
      ],
    );
  }

  Widget _buildRemoveFriendButton(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showConfirmationDialog(
          context,
          'Remove ${profileUser.name} from your friends?',
          Icons.person_remove_outlined,
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPallete.errorColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_remove_outlined,
              color: AppPallete.errorColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              "Remove Friend",
              style: TextStyle(
                color: AppPallete.errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendMessageButton(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return GestureDetector(
      onTap: () {
        if (widget.isEmbedded) {
          widget.onClose?.call();
          context.read<NavPageIndexCubit>().navigateToChat(
            profileUser.id as String,
            profileUser.name as String,
          );
        } else {
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
            Icon(
              Icons.chat_bubble_outline,
              color: AppPallete.whiteColor,
              size: 28,
            ),
            const SizedBox(width: 14),
            Text(
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

  Widget _buildRequestSentDisplay(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    return GestureDetector(
      onTap: () => _showCancelRequestDialog(context, profileUser, currentUser),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPallete.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppPallete.greyText,
              size: 28,
            ),
            const SizedBox(width: 14),
            Text(
              "Request Sent",
              style: TextStyle(
                color: AppPallete.greyText,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelRequestDialog(
    BuildContext context,
    dynamic profileUser,
    dynamic currentUser,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
