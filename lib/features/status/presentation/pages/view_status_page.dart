import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

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

  final StoryController controller = StoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<StoryItem> storyItems = widget.statuses.map((status) {

      return StoryItem.pageImage(
        url: status.imageUrl,
        controller: controller,

        caption: Text(
          status.caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );

    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// Story Viewer
          StoryView(
            storyItems: storyItems,
            controller: controller,
            repeat: false,
            onComplete: () {
              Navigator.pop(context);
            },
          ),

          /// Username + time at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [

                  //const CircleAvatar(),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        widget.statuses.first.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        widget.statuses.first.createdAt.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}