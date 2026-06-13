import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/presentation/bloc/personal_time_line/personal_timeline_bloc.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';
import 'package:chat_application/features/timeline/presentation/widgets/add_event_dialog.dart';
import 'package:chat_application/features/timeline/presentation/widgets/event_detail_dialog.dart';
import 'package:chat_application/features/timeline/presentation/widgets/timeline_bubble.dart';
import 'package:chat_application/features/timeline/presentation/widgets/timeline_options_tray.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalTimeLinePage extends StatefulWidget {
  final String userId;

  PersonalTimeLinePage({super.key, required this.userId});

  @override
  State<PersonalTimeLinePage> createState() => _PersonalTimeLinePageState();
}

class _PersonalTimeLinePageState extends State<PersonalTimeLinePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _contentSlide;
  final _kbFocusNode = FocusNode();

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
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _kbFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: KeyboardListener(
        focusNode: _kbFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        },
        child: Container(
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _contentSlide,
                child: PersonalTimelineContent(
                  userId: widget.userId,
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalTimelineContent extends StatefulWidget {
  final String userId;
  final VoidCallback onClose;

  const PersonalTimelineContent({
    super.key,
    required this.userId,
    required this.onClose,
  });

  @override
  State<PersonalTimelineContent> createState() => _PersonalTimelineContentState();
}

class _PersonalTimelineContentState extends State<PersonalTimelineContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PersonalTimelineBloc>().add(
        FetchPersonalTimeLine(userId: widget.userId),
      );
    });
  }

  Future<void> _onFabPressed() async {
    final result = await AddEventDialog.show(context);

    if (result != null && context.mounted) {
      context.read<PersonalTimelineBloc>().add(
        AddPersonalTimeLineEvent(
          userId: widget.userId,
          title: result.title,
          content: result.content,
          time: DateTime.now(),
          type: "text",
          image: result.image,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: BlocBuilder<
                PersonalTimelineBloc,
                PersonalTimelineState
              >(
                builder: (context, state) {
                  if (state is TimelineLoading) {
                    return const Loader();
                  }

                  if (state is PersonalTimelineLoaded) {
                    if (state.events.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      cacheExtent: 100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: state.events.length,
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        final isMe = index % 2 == 0;

                        return _timelineItem(
                          event,
                          isMe,
                          index == state.events.length - 1,
                          context,
                        );
                      },
                    );
                  }

                  if (state is PersonalTimelineError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: AppPallete.errorColor),
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppPallete.primaryOrange,
            onPressed: _onFabPressed,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onClose(),
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
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.whiteColor,
                  letterSpacing: -0.5,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPallete.cardBg.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 40,
                color: AppPallete.greyText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No timeline events yet",
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

  Widget _timelineItem(Event event, bool isMe, bool last, BuildContext c) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child:
                isMe
                    ? const SizedBox()
                    : Align(
                      alignment: Alignment.centerRight,
                      child: _bubble(event, false, c),
                    ),
          ),

          Column(
            children: [
              Expanded(child: Container(width: 2, color: AppPallete.divider)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color(event.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon(event.type),
                  size: 14,
                  color: AppPallete.whiteColor,
                ),
              ),
              !last
                  ? Expanded(
                    child: Container(width: 2, color: AppPallete.divider),
                  )
                  : Expanded(
                    child: Container(width: 2, color: Colors.transparent),
                  ),
            ],
          ),

          Expanded(
            child:
                isMe
                    ? Align(
                      alignment: Alignment.centerLeft,
                      child: _bubble(event, true, c),
                    )
                    : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Event event, bool isMe, BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        TimelineOptionsTray.show(
          context: context,
          position: details.globalPosition,
          onDelete: () {
            context.read<PersonalTimelineBloc>().add(
              RemovePersonalTimelineEvent(
                userId: widget.userId,
                eventId: event.id,
              ),
            );
          },
        );
      },
      child: TimelineBubble(
        event: event,
        isMe: isMe,
        userId: widget.userId,
        onTap: () => EventDetailDialog.show(context, event),
      ),
    );
  }

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

  Color _color(String type) {
    switch (type) {
      case "image":
        return Colors.blue;
      case "milestone":
        return AppPallete.primaryOrange;
      default:
        return AppPallete.primaryOrange;
    }
  }
}
