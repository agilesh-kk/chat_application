import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/profile_pic_provider.dart';
import 'package:flutter/material.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';

class ParticipantAvatars extends StatelessWidget {
  final List<W2GParticipant> participants;
  final int maxDisplay;

  const ParticipantAvatars({
    super.key,
    required this.participants,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    final display = participants.take(maxDisplay).toList();
    final overflow = participants.length - maxDisplay;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...display.map((p) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppPallete.darkTertiary,
            backgroundImage: p.profilePic.isNotEmpty
                ? ProfilePicProvider.resolve(p.profilePic) as ImageProvider?
                : null,
            child: p.profilePic.isEmpty
                ? Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppPallete.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
        )),
        if (overflow > 0)
          CircleAvatar(
            radius: 16,
            backgroundColor: AppPallete.primaryOrange,
            child: Text(
              '+$overflow',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
