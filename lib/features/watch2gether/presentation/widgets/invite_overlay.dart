import 'dart:async';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:chat_application/features/watch2gether/presentation/pages/w2g_room_page.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:flutter/material.dart';

class InviteOverlay extends StatefulWidget {
  final Widget child;
  final String? currentUserId;

  const InviteOverlay({
    super.key,
    required this.child,
    this.currentUserId,
  });

  @override
  State<InviteOverlay> createState() => _InviteOverlayState();
}

class _InviteOverlayState extends State<InviteOverlay> {
  StreamSubscription<Map<String, dynamic>>? _inviteSub;
  final List<_PendingInvite> _invites = [];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(InviteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserId != oldWidget.currentUserId) {
      _startListening();
    }
  }

  void _startListening() {
    _inviteSub?.cancel();
    if (widget.currentUserId == null || widget.currentUserId!.isEmpty) return;

    final repository = serviceLocator<W2GRepository>();
    _inviteSub = repository.getInvitesStream(widget.currentUserId!).listen((invites) {
      invites.forEach((roomId, data) {
        if (data is Map && _invites.any((i) => i.roomId == roomId)) return;
        if (data is Map) {
          final invite = _PendingInvite(
            roomId: roomId,
            roomName: data['roomName'] as String? ?? 'Room',
            hostName: data['hostName'] as String? ?? 'Someone',
            hostId: data['hostId'] as String? ?? '',
          );
          setState(() => _invites.add(invite));
          _startTimer(invite);
        }
      });

      final activeRoomIds = invites.keys.toSet();
      setState(() => _invites.removeWhere((i) => !activeRoomIds.contains(i.roomId)));
    });
  }

  void _startTimer(_PendingInvite invite) {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _invites.remove(invite));
        final uid = widget.currentUserId;
        if (uid != null) serviceLocator<W2GRepository>().deleteInvite(uid, invite.roomId);
      }
    });
  }

  void _acceptInvite(_PendingInvite invite) {
    final uid = widget.currentUserId;
    if (uid == null) return;
    serviceLocator<W2GRepository>().deleteInvite(uid, invite.roomId);
    setState(() => _invites.remove(invite));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => W2GRoomPage(
        roomId: invite.roomId,
        userId: uid,
      )),
    );
  }

  void _declineInvite(_PendingInvite invite) {
    final uid = widget.currentUserId;
    if (uid == null) return;
    serviceLocator<W2GRepository>().deleteInvite(uid, invite.roomId);
    setState(() => _invites.remove(invite));
  }

  @override
  void dispose() {
    _inviteSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_invites.isNotEmpty)
          Positioned(
            top: 8,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _invites.map((invite) => _buildInviteCard(invite)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildInviteCard(_PendingInvite invite) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPallete.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPallete.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${invite.hostName} invited you',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Join "${invite.roomName}"',
                      style: TextStyle(color: AppPallete.greyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _acceptInvite(invite),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPallete.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _declineInvite(invite),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPallete.darkTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppPallete.greyText, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingInvite {
  final String roomId;
  final String roomName;
  final String hostName;
  final String hostId;

  _PendingInvite({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    required this.hostId,
  });
}
