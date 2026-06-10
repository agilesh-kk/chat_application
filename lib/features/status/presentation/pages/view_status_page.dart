import 'dart:async';
import 'dart:io';

import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/bloc/status_view/statusview_bloc.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewStatusPage extends StatefulWidget {
  final List<Status> statuses;
  final String userProfilePic;
  final bool isUserStatus;
  final bool hasInternet;
  final String userName;

  const ViewStatusPage({
    super.key,
    required this.statuses,
    required this.isUserStatus,
    required this.hasInternet,
    required this.userProfilePic,
    required this.userName,
  });

  @override
  State<ViewStatusPage> createState() => _ViewStatusPageState();
}

class _ViewStatusPageState extends State<ViewStatusPage> {
  late PageController pageController;
  int currentIndex = 0;
  Timer? timer;
  double progress = 0;
  bool _isCaptionExpanded = false;
  bool _isUIVisible = true;
  final Duration storyDuration = const Duration(seconds: 5);

  void toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
    if (_isUIVisible) {
      resumeStory();
    } else {
      pauseStory();
    }
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    startStoryTimer();
  }

  void startStoryTimer() {
    timer?.cancel();
    progress = progress <= 1 ? progress : 0;
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        progress += 0.01;
      });

      if (progress >= 1) {
        nextStory();
      }
    });
  }

  void nextStory() {
    if (currentIndex < widget.statuses.length - 1) {
      currentIndex++;
      pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      progress = 0;
      _isCaptionExpanded = false;
      startStoryTimer();
    } else {
      timer?.cancel();
      Navigator.pop(context);
    }
  }

  void previousStory() {
    if (currentIndex > 0) {
      currentIndex--;
      pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      progress = 0;
      startStoryTimer();
    }
  }

  void pauseStory() {
    timer?.cancel();
  }

  void resumeStory() {
    startStoryTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: BlocConsumer<StatusviewBloc, StatusviewState>(
        listener: (context, state) async {
          if (state is ViewDisplaySuccess) {
            pauseStory();
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppPallete.cardBg,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPallete.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: AppPallete.divider,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        height: 4,
                        width: 36,
                        decoration: BoxDecoration(
                          color: AppPallete.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 20,
                              color: AppPallete.greyText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${state.statusView.length} views",
                              style: const TextStyle(
                                color: AppPallete.whiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color: AppPallete.divider,
                      ),
                      Flexible(
                        child: BlocBuilder<FriendsCubit, FriendsState>(
                          builder: (context, friendsState) {
                            Map<String, FriendModel> friendsMap = {};
                            if (friendsState is FriendsLoaded) {
                              friendsMap = friendsState.friends;
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: state.statusView.length,
                              itemBuilder: (context, index) {
                                final viewer = state.statusView[index];
                                final friend = friendsMap[viewer.viewerId];
                                final profilePic = friend?.profilePic;
                                final hasProfilePic =
                                    profilePic != null && profilePic.isNotEmpty;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: hasProfilePic
                                            ? profileImageProvider(profilePic)
                                            : null,
                                        backgroundColor: AppPallete.darkSecondary,
                                        child: !hasProfilePic
                                            ? const Icon(
                                                Icons.person,
                                                size: 20,
                                                color: AppPallete.greyText,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              viewer.viewerName,
                                              style: const TextStyle(
                                                color: AppPallete.whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              MomentsAgo.calculateMomentsAgo(
                                                viewer.viewedAt
                                                    .toLocal()
                                                    .toString(),
                                              ),
                                              style: const TextStyle(
                                                color: AppPallete.greyText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
            resumeStory();
          }
        },
        builder: (context, state) {
          final status = widget.statuses[currentIndex];

          return GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 2) {
                previousStory();
              } else {
                nextStory();
              }
            },
            onLongPressStart: (_){
              toggleUIVisibility();
              pauseStory();
            },
            onLongPressEnd: (_){
              toggleUIVisibility();
              resumeStory();
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.statuses.length,
                  itemBuilder: (context, index) {
                    if (widget.statuses[index].localPath != null) {
                      return Image.file(
                        File(widget.statuses[index].localPath!),
                        fit: BoxFit.contain,
                      );
                    }
                    return Image.network(
                      widget.statuses[index].imageUrl,
                      fit: BoxFit.contain,
                    );
                  },
                ),
                // Top UI elements
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _isUIVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            _buildProgressBars(),
                            const SizedBox(height: 12),
                            _buildUserInfo(status),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom section - always show caption container (transparent if empty)
                Positioned(
                  bottom: 25,
                  left: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _isUIVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: status.caption.isNotEmpty
                                  ? AppPallete.darkBg.withValues(alpha: 0.75)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: status.caption.isNotEmpty
                                  ? Border.all(
                                      color: AppPallete.primaryOrange
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: status.caption.isNotEmpty
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              _isCaptionExpanded ? 200 : 75,
                                        ),
                                        child: SingleChildScrollView(
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: _isCaptionExpanded
                                                      ? status.caption
                                                      : (status.caption.length > 100
                                                          ? '${status.caption.substring(0, 100)}...'
                                                          : status.caption),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (status.caption.length > 100)
                                                  WidgetSpan(
                                                    alignment: PlaceholderAlignment.middle,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _isCaptionExpanded =
                                                              !_isCaptionExpanded;
                                                        });
                                                        if(_isCaptionExpanded){
                                                          pauseStory();
                                                        }else{
                                                          resumeStory();
                                                        }
                                                      },
                                                      child: Text(
                                                        _isCaptionExpanded
                                                            ? '  Show less'
                                                            : '  Read more',
                                                        style: TextStyle(
                                                          color: AppPallete
                                                              .primaryOrange,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        if (widget.isUserStatus && widget.hasInternet)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () {
                                context.read<StatusviewBloc>().add(
                                      GetViewEvent(statusId: status.id),
                                    );
                              },
                              child:  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppPallete.cardBg
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppPallete.divider),
                                    ),
                                    child: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 18,
                                      color: AppPallete.primaryOrange,
                                    )
                              )
                            )
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(
        widget.statuses.length,
        (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: index < currentIndex
                      ? 1
                      : index == currentIndex
                          ? progress
                          : 0,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(AppPallete.primaryOrange),
                  minHeight: 3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(Status status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppPallete.primaryOrange,
                AppPallete.lightOrange,
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: profileImageProvider(widget.userProfilePic),
            backgroundColor: AppPallete.darkSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                MomentsAgo.calculateMomentsAgo(
                  status.createdAt.toLocal().toString(),
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (widget.isUserStatus && widget.hasInternet)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppPallete.cardBg,
            onSelected: (value) {
              if (value == 'delete') {
                pauseStory();
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: AppPallete.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppPallete.divider),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppPallete.errorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: AppPallete.errorColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Delete Status',
                                style: TextStyle(
                                  color: AppPallete.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Are you sure you want to delete this status?',
                            style: TextStyle(
                              color: AppPallete.greyText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildDialogButton(
                                label: 'Cancel',
                                isPrimary: false,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  resumeStory();
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildDialogButton(
                                label: 'Delete',
                                isPrimary: true,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.read<StatusBloc>().add(
                                    DeleteStatusEvent(statusId: status.id),
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete status'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDialogButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppPallete.errorColor : AppPallete.darkTertiary,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppPallete.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppPallete.whiteColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
