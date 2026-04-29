import 'dart:async';
import 'dart:io';

import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/bloc/status_view/statusview_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewStatusPage extends StatefulWidget {
  final List<Status> statuses;
  final String userProfilePic;
  final bool isUserStatus;
  final bool hasInternet;

  const ViewStatusPage({
    super.key,
    required this.statuses,
    required this.isUserStatus,
    required this.hasInternet,
    required this.userProfilePic,
  });

  @override
  State<ViewStatusPage> createState() => _ViewStatusPageState();
}

class _ViewStatusPageState extends State<ViewStatusPage> {
  late PageController pageController;
  int currentIndex = 0;
  Timer? timer;
  double progress = 0;
  final Duration storyDuration = const Duration(seconds: 5);

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
      backgroundColor: Colors.black,
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
                  height: 350,
                  decoration: BoxDecoration(
                    color: AppPallete.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppPallete.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "${state.statusView.length} views",
                        style: const TextStyle(
                          color: AppPallete.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: AppPallete.divider),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.statusView.length,
                          itemBuilder: (context, index) {
                            final viewer = state.statusView[index];
                            return ListTile(
                              title: Text(
                                viewer.viewerName,
                                style: const TextStyle(
                                  color: AppPallete.whiteColor,
                                ),
                              ),
                              subtitle: Text(
                                MomentsAgo.calculateMomentsAgo(
                                  viewer.viewedAt.toLocal().toString(),
                                ),
                                style: const TextStyle(
                                  color: AppPallete.greyText,
                                  fontSize: 12,
                                ),
                              ),
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
            onLongPressStart: (_) => pauseStory(),
            onLongPressEnd: (_) => resumeStory(),
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                if (status.caption.isNotEmpty)
                  Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                if (widget.isUserStatus && widget.hasInternet)
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 28,
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          context.read<StatusviewBloc>().add(
                                GetViewEvent(statusId: status.id),
                              );
                        },
                      ),
                    ),
                  ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    iconSize: 28,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
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
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
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
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(widget.userProfilePic),
            backgroundColor: AppPallete.cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status.userName,
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
      ],
    );
  }
}