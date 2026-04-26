import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/presentation/bloc/timeline_bloc.dart';
import 'package:chat_application/features/timeline/presentation/widgets/timeline_bubble.dart';
import 'package:chat_application/features/timeline/presentation/widgets/timeline_options_tray.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:chat_application/init_dependencies.dart';

class TimelinePage extends StatelessWidget {
  final String userId;
  final String receiverId;
  final String receiverName;
  late final TimelineBloc tb;

  TimelinePage({
    super.key,
    required this.userId,
    required this.receiverId,
    required this.receiverName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timeline")),
      // floatingActionButton: FloatingActionButton(
      //   shape: CircleBorder(),
      //   backgroundColor: const Color.fromARGB(255, 246, 144, 11),
      //   foregroundColor: Colors.white,
      //   onPressed: () {
      //     tb.add(
      //       RefreshTimelineEvent(
      //         userId: userId,
      //         receiverId: receiverId,
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.refresh),
      // ),
      body: BlocProvider(
        create: (context) { tb = serviceLocator<TimelineBloc>()
          ..add(
            FetchTimelineEvent(
              userId: userId,
              receiverId: receiverId,
            ),
          );
          return tb;
        },
        child: BlocBuilder<TimelineBloc, TimelineState>(
          builder: (context, state) {
            if (state is TimelineLoading) {
              return const Center(child: CircularProgressIndicator());
            }
    
            if (state is TimelineLoaded) {
              return ListView.builder(
                cacheExtent: 100,
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
    
                  /// IMPORTANT: requires senderId in model
                  final isMe = index%2 == 0;
    
                  return _timelineItem(
                    event, 
                    isMe, 
                    index == state.events.length-1,
                    context)
                  ;
                },
              );
            }
    
            if (state is TimelineError) {
              return Center(child: Text(state.message));
            }
    
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// =======================
  /// TIMELINE ITEM
  /// =======================
  Widget _timelineItem(dynamic event, bool isMe, bool last, BuildContext c) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// LEFT SIDE (always takes equal space)
        Expanded(
          child: isMe
              ? const SizedBox()
              : Align(
                  alignment: Alignment.centerRight,
                  child: _bubble(event, isMe, c),
                ),
        ),

        /// CENTER LINE (fixed width)
        Column(
          children: [
            Expanded(
              child: Container(width: 2, color: Colors.grey.shade400),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _color(event.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(event.type),
                size: 14,
                color: Colors.white,
              ),
            ),
            !last ? Expanded(
              child: Container(width: 2, color: Colors.grey.shade400),
            ) : Expanded(
              child: Container(width: 2, color: Colors.transparent),
            ),
          ],
        ),

        /// RIGHT SIDE (always takes equal space)
        Expanded(
          child: isMe
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: _bubble(event, isMe, c),
                )
              : const SizedBox(),
        ),
      ],
    ),
  );
}

  /// =======================
  /// MESSAGE BUBBLE
  /// =======================
  Widget _bubble(dynamic event, bool isMe, BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        final fullId = (event as Event).id;
        final messageId = fullId.split("_")[0];
        // print("Timeline ID: ${event.id}");
        // print("Extracted messageId: $messageId");

        Navigator.pop(context, messageId);
        //Navigator.pop(c,(event as Event).id);
      },
      onLongPressStart: (details){
        TimelineOptionsTray.show(
          context: context,
          position: details.globalPosition,
          onDelete: (){
            context.read<TimelineBloc>().add(
              RemoveEvent(
                eventId: event.id, 
                messageId: event.messageId, 
                userId: userId, 
                receiverId: receiverId,
              )
            );
          }
        );
      },
      child: TimelineBubble(
        event: event, 
        isMe: isMe,
        receiverId: receiverId,
        userId: userId,
      )
      );
  }

  /// =======================
  /// ICON
  /// =======================
  IconData _icon(String type) {
    switch (type) {
      case "image":
        return Icons.image;
      case "milestone":
        return Icons.star;
      default:
        return Icons.message;
    }
  }

  /// =======================
  /// COLOR
  /// =======================
  Color _color(String type) {
    switch (type) {
      case "image":
        return Colors.blue;
      case "milestone":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}