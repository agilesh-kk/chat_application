import 'dart:async';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:flutter/material.dart';

class ViewStatusPage extends StatefulWidget {
  final List<Status> statuses;

  const ViewStatusPage({
    super.key,
    required this.statuses,
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
    progress = 0;
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

    final status = widget.statuses[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
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
            /// IMAGE VIEWER
            PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.statuses.length,
              itemBuilder: (context, index) {

                return Image.network(
                  widget.statuses[index].imageUrl,
                  fit: BoxFit.contain,
                );

              },
            ),

            /// TOP UI
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    /// PROGRESS BARS
                    Row(
                      children: List.generate(widget.statuses.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: index < currentIndex
                                  ? 1
                                  : index == currentIndex
                                      ? progress
                                      : 0,
                              backgroundColor: Colors.white30,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        );

                      }),
                    ),

                    const SizedBox(height: 10),

                    /// USER INFO
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            Text(
                              //status.createdAt.toLocal().toString(),
                              MomentsAgo.calculateMomentsAgo(status.createdAt.toLocal().toString()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// CAPTION
            if (status.caption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Text(
                  status.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}