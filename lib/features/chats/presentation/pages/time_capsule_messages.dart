import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/time_capsule/time_capsule_bloc.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TimeCapsuleMessages extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String? receiverName;

  const TimeCapsuleMessages({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    this.receiverName,
  });

  @override
  State<TimeCapsuleMessages> createState() => _TimeCapsuleMessagesState();
}

class _TimeCapsuleMessagesState extends State<TimeCapsuleMessages>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlide;
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
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
    _loadMessages();
  }

  void _loadMessages() {
    context.read<TimeCapsuleBloc>().add(
      LoadScheduledMessagesEvent(
        userId: widget.currentUserId,
        receiverId: widget.receiverId,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: _buildHeader(context),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _contentSlide,
                    child: BlocBuilder<TimeCapsuleBloc, TimeCapsuleState>(
                      builder: (context, state) {
                        if (state is TimeCapsuleLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppPallete.primaryOrange,
                            ),
                          );
                        }

                        if (state is TimeCapsuleError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppPallete.errorColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: AppPallete.errorColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Something went wrong',
                                    style: TextStyle(
                                      color: AppPallete.whiteColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.message,
                                    style: TextStyle(
                                      color: AppPallete.greyText,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  GestureDetector(
                                    onTap: _loadMessages,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppPallete.primaryOrange,
                                            AppPallete.lightOrange,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: TextStyle(
                                          color: AppPallete.whiteColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is TimeCapsuleLoaded) {
                          final messages = state.messages;

                          if (messages.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return _buildScheduledTile(message);
                            },
                          );
                        }
                        return const SizedBox();
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
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
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time Capsules',
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
                Icons.lock_clock,
                size: 40,
                color: AppPallete.greyText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No scheduled messages",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Long press send button to create\ntime capsule",
              style: TextStyle(color: AppPallete.greyText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledTile(Message message) {
    final scheduledTime = message.sendAt;
    final isScheduled = scheduledTime != null;
    final isPast = isScheduled && scheduledTime.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isPast
                    ? AppPallete.errorColor.withValues(alpha: 0.5)
                    : AppPallete.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_clock,
                    color: AppPallete.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScheduled
                            ? 'Scheduled for ${DateFormat('MMM d, h:mm a').format(scheduledTime)}'
                            : 'Pending',
                        style: TextStyle(
                          color: AppPallete.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (isPast)
                        Text(
                          'Message sent',
                          style: TextStyle(
                            color: AppPallete.errorColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    DeleteMessageConfirmationDialog.show(
                      context,
                      messageContent: message.content,
                      onDeleteForMe: () {
                        context.read<ChatBloc>().add(
                          DeleteMessageEvent(
                            msgId: message.id,
                            userId: widget.currentUserId,
                            type: message.type,
                            receiverId: widget.receiverId,
                            deleteForEveryone: false,
                          ),
                        );
                      },
                      onDeleteForEveryone: () {
                        context.read<ChatBloc>().add(
                          DeleteMessageEvent(
                            msgId: message.id,
                            userId: widget.currentUserId,
                            type: message.type,
                            receiverId: widget.receiverId,
                            deleteForEveryone: true,
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppPallete.errorColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.darkTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.content,
                style: TextStyle(color: AppPallete.whiteColor, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
