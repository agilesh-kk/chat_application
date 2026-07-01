import 'dart:async';
import 'dart:io';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/bloc/status_view/statusview_bloc.dart';
import 'package:chat_application/features/status/presentation/models/user_status_batch.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewStatusPage extends StatefulWidget {
  final List<UserStatusBatch> userStatusBatches;
  final int startBatchIndex;
  final int startStatusIndex;
  final bool hasInternet;
  final bool fromChat;

  const ViewStatusPage({
    super.key,
    required this.userStatusBatches,
    this.startBatchIndex = 0,
    this.startStatusIndex = 0,
    this.hasInternet = true,
    this.fromChat = false,
  });

  @override
  State<ViewStatusPage> createState() => _ViewStatusPageState();
}

class _ViewStatusPageState extends State<ViewStatusPage> {
  late PageController pageController;
  late List<Status> _flatStatuses;
  late List<int> _batchStartIndices;
  int _currentFlatIndex = 0;
  Timer? timer;
  double progress = 0;
  bool _isCaptionExpanded = false;
  bool _isUIVisible = true;
  bool _isPaused = false;
  final Duration storyDuration = const Duration(seconds: 5);
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  final FocusNode _kbFocusNode = FocusNode();

  int get _currentBatchIndex {
    for (int i = _batchStartIndices.length - 1; i >= 0; i--) {
      if (_currentFlatIndex >= _batchStartIndices[i]) return i;
    }
    return 0;
  }

  UserStatusBatch get _currentBatch => widget.userStatusBatches[_currentBatchIndex];

  bool get _isCurrentUserBatch {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is! AppUserIsSignedin) return false;
    return _currentBatch.userId == appUserState.user.id;
  }

  void _buildFlatStatuses() {
    _flatStatuses = [];
    _batchStartIndices = [];
    for (final batch in widget.userStatusBatches) {
      _batchStartIndices.add(_flatStatuses.length);
      _flatStatuses.addAll(batch.statuses);
    }
  }

  void toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _buildFlatStatuses();
    if (_batchStartIndices.isNotEmpty) {
      final batchStart = _batchStartIndices[widget.startBatchIndex.clamp(0, _batchStartIndices.length - 1)];
      final batch = widget.userStatusBatches[widget.startBatchIndex.clamp(0, widget.userStatusBatches.length - 1)];
      final clampedStatusIndex = widget.startStatusIndex.clamp(0, batch.statuses.length - 1);
      _currentFlatIndex = batchStart + clampedStatusIndex;
    } else {
      _currentFlatIndex = 0;
    }
    pageController = PageController(initialPage: _currentFlatIndex);
    startStoryTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _markCurrentStatusAsViewed();
    });
    _replyFocusNode.addListener(_onReplyFocusChange);
  }

  void _markCurrentStatusAsViewed() {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is! AppUserIsSignedin) return;
    final currentUserId = appUserState.user.id;
    final currentUserName = appUserState.user.name;
    if (_isCurrentUserBatch) return;
    final status = _flatStatuses[_currentFlatIndex];
    if (status.isViewed) return;
    context.read<StatusBloc>().add(
      UpdateViewEvent(
        statusId: status.id,
        viewerId: currentUserId,
        viewerName: currentUserName,
      ),
    );
  }

  void startStoryTimer() {
    timer?.cancel();
    if (_isPaused) return;
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

  void togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      pauseStory();
    } else {
      resumeStory();
    }
  }

  void nextStory() {
    if (_currentFlatIndex < _flatStatuses.length - 1) {
      _currentFlatIndex++;
      pageController.animateToPage(
        _currentFlatIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      progress = 0;
      _isCaptionExpanded = false;
      startStoryTimer();
      _markCurrentStatusAsViewed();
    } else {
      timer?.cancel();
      Navigator.pop(context);
    }
  }

  void previousStory() {
    if (_currentFlatIndex > 0) {
      _currentFlatIndex--;
      pageController.animateToPage(
        _currentFlatIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      progress = 0;
      startStoryTimer();
      _markCurrentStatusAsViewed();
    }
  }

  void _goToNextUser() {
    final nextBatch = _currentBatchIndex + 1;
    if (nextBatch < widget.userStatusBatches.length) {
      setState(() {
        _currentFlatIndex = _batchStartIndices[nextBatch];
        progress = 0;
        _isCaptionExpanded = false;
      });
      pageController.jumpToPage(_currentFlatIndex);
      startStoryTimer();
      _markCurrentStatusAsViewed();
    }
  }

  void _goToPreviousUser() {
    final prevBatch = _currentBatchIndex - 1;
    if (prevBatch >= 0) {
      setState(() {
        _currentFlatIndex = _batchStartIndices[prevBatch];
        progress = 0;
      });
      pageController.jumpToPage(_currentFlatIndex);
      startStoryTimer();
      _markCurrentStatusAsViewed();
    }
  }

  void pauseStory() {
    timer?.cancel();
  }

  void resumeStory() {
    if (!_isPaused) startStoryTimer();
  }

  void _onReplyFocusChange() {
    if (_replyFocusNode.hasFocus) {
      pauseStory();
    } else {
      if (!_isPaused) resumeStory();
    }
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    pauseStory();

    final status = _flatStatuses[_currentFlatIndex];
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is! AppUserIsSignedin) {
      resumeStory();
      return;
    }

    context.read<StatusBloc>().add(ReplyToStatusEvent(
      receiverId: status.userId,
      userId: appUserState.user.id,
      content: text,
      userName: appUserState.user.name,
      userProfile: appUserState.user.profilePic ?? '',
      statusId: status.id,
      statusUserId: status.userId,
      statusImageUrl: status.imageUrl,
      statusCaption: status.caption,
      statusCreatedAt: status.createdAt,
      statusExpiresAt: status.expiresAt,
      statusUserName: status.userName,
      statusProfilepic: status.profilepic,
    ));

    _replyController.clear();
    _replyFocusNode.unfocus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reply sent to ${_currentBatch.userName}"),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    resumeStory();
  }

  @override
  void dispose() {
    timer?.cancel();
    pageController.dispose();
    _replyController.dispose();
    _replyFocusNode.removeListener(_onReplyFocusChange);
    _replyFocusNode.dispose();
    _kbFocusNode.dispose();
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
            final currentStatusId = _flatStatuses[_currentFlatIndex].id;
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
                final blocState = context.read<StatusBloc>().state;
                final likedBy = blocState is StatusDisplaySuccess
                    ? (blocState.status.where((s) => s.id == currentStatusId).firstOrNull?.likedBy ?? <String>[])
                    : <String>[];

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
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    viewer.viewerName,
                                                    style: const TextStyle(
                                                      color: AppPallete.whiteColor,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                if (likedBy.contains(viewer.viewerId))
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 6),
                                                    child: Icon(
                                                      Icons.favorite,
                                                      size: 14,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                              ],
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
                      if (likedBy.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${likedBy.length} likes',
                                style: const TextStyle(
                                  color: AppPallete.greyText,
                                  fontSize: 13,
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
            resumeStory();
          }
        },
        builder: (context, state) {
          final status = _flatStatuses[_currentFlatIndex];
          final appUserState = context.read<AppUserCubit>().state;
          final currentUserId = appUserState is AppUserIsSignedin
              ? appUserState.user.id
              : '';
          final statusBlocState = context.watch<StatusBloc>().state;
          final liveStatus = statusBlocState is StatusDisplaySuccess
              ? (statusBlocState.status.where((s) => s.id == status.id).firstOrNull ?? status)
              : status;

          return KeyboardListener(
            focusNode: _kbFocusNode,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  if (_replyFocusNode.hasFocus) {
                    _replyFocusNode.unfocus();
                  } else {
                    Navigator.pop(context);
                  }
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  previousStory();
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  nextStory();
                }
              }
            },
            child: GestureDetector(
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
              if (_isUIVisible && !_isPaused) {
                resumeStory();
              }
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _flatStatuses.length,
                  itemBuilder: (context, index) {
                    if (_flatStatuses[index].localPath != null) {
                      return Image.file(
                        File(_flatStatuses[index].localPath!),
                        fit: BoxFit.contain,
                      );
                    }
                    return Image.network(
                      _flatStatuses[index].imageUrl,
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
                // Navigation buttons overlay - top right
                if (!_isCurrentUserBatch)
                  Positioned(
                    top: 125,
                    right: 12,
                    child: AnimatedOpacity(
                      opacity: _isUIVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavButton(
                            icon: Icons.skip_previous,
                            onTap: _currentBatchIndex > 0 ? _goToPreviousUser : null,
                          ),
                          const SizedBox(height: 12),
                          _buildNavButton(
                            icon: _isPaused ? Icons.play_arrow : Icons.pause,
                            onTap: () {
                              togglePause();
                              toggleUIVisibility();
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildNavButton(
                            icon: Icons.skip_next,
                            onTap: _currentBatchIndex < widget.userStatusBatches.length - 1 ? _goToNextUser : null,
                          ),
                        ],
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
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
                            if (!_isCurrentUserBatch)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<StatusBloc>().add(
                                      AddLikeEvent(
                                        statusId: status.id,
                                        userId: currentUserId,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppPallete.cardBg
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppPallete.divider),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          liveStatus.likedBy.contains(currentUserId)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 18,
                                          color: liveStatus.likedBy.contains(currentUserId)
                                              ? Colors.red
                                              : AppPallete.primaryOrange,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_isCurrentUserBatch && widget.hasInternet)
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
                        if (!widget.fromChat) ...[
                          const SizedBox(height: 8),
                          _buildReplyInput(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      );
      },
    ),
  );
}

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppPallete.cardBg.withValues(alpha: 0.8)
              : AppPallete.cardBg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: onTap != null
                ? AppPallete.divider
                : AppPallete.divider.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null
              ? AppPallete.whiteColor
              : AppPallete.greyText.withValues(alpha: 0.4),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    final batch = _currentBatch;
    final batchStart = _batchStartIndices[_currentBatchIndex];
    return Row(
      children: List.generate(
        batch.statuses.length,
        (index) {
          final globalIndex = batchStart + index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: globalIndex < _currentFlatIndex
                      ? 1
                      : globalIndex == _currentFlatIndex
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
    final batch = _currentBatch;
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
            backgroundImage: batch.profilePic.startsWith('assets/')
                ? AssetImage(batch.profilePic) as ImageProvider
                : NetworkImage(batch.profilePic),
            backgroundColor: AppPallete.darkSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batch.userName,
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
        if (_isCurrentUserBatch && widget.hasInternet)
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

  Widget _buildReplyInput() {
    if (widget.fromChat) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              focusNode: _replyFocusNode,
              style: const TextStyle(color: AppPallete.whiteColor, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Reply to status...",
                hintStyle: TextStyle(color: AppPallete.greyText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendReply(),
            ),
          ),
          GestureDetector(
            onTap: _sendReply,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 16, color: AppPallete.whiteColor),
            ),
          ),
        ],
      ),
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
