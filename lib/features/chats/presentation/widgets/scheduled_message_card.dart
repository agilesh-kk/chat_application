import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduledMessageCard extends StatefulWidget {
  final Message message;
  final String currentUserId;
  final String receiverId;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;

  const ScheduledMessageCard({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.receiverId,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
  });

  @override
  State<ScheduledMessageCard> createState() => _ScheduledMessageCardState();
}

class _ScheduledMessageCardState extends State<ScheduledMessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isPast =>
      widget.message.sendAt != null &&
      widget.message.sendAt!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPast
                  ? [AppPallete.cardBg, AppPallete.darkTertiary]
                  : [AppPallete.primaryOrange.withValues(alpha: 0.3), AppPallete.lightOrange.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPast
                  ? AppPallete.errorColor.withValues(alpha: 0.4)
                  : AppPallete.primaryOrange.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: _isPast
                    ? Colors.transparent
                    : AppPallete.primaryOrange.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPast
                          ? AppPallete.errorColor.withValues(alpha: 0.2)
                          : AppPallete.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_clock,
                      color: _isPast ? AppPallete.errorColor : AppPallete.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.sendAt != null
                              ? 'Scheduled for ${DateFormat('MMM d, h:mm a').format(widget.message.sendAt!)}'
                              : 'Pending',
                          style: TextStyle(
                            color: AppPallete.whiteColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_isPast)
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
                        messageContent: widget.message.content,
                        onDeleteForMe: widget.onDeleteForMe,
                        onDeleteForEveryone: widget.onDeleteForEveryone,
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
                  widget.message.content,
                  style: TextStyle(color: AppPallete.whiteColor, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
