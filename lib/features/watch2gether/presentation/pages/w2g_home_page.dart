import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/pages/w2g_room_page.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/create_room_bottom_sheet.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class W2GHomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userProfilePic;

  const W2GHomePage({
    super.key,
    required this.userId,
    this.userName = '',
    this.userProfilePic = '',
  });

  @override
  State<W2GHomePage> createState() => _W2GHomePageState();
}

class _W2GHomePageState extends State<W2GHomePage> {
  final _joinCodeController = TextEditingController();
  bool _showJoinInput = false;

  @override
  void initState() {
    super.initState();
    context.read<W2GBloc>().add(W2GLoadRooms(userId: widget.userId));
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return BlocConsumer<W2GBloc, W2GState>(
            listenWhen: (previous, current) =>
                current is W2GRoomCreated || (current is W2GError && previous is W2GLoading),
            listener: (context, state) {
              if (state is W2GRoomCreated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => W2GRoomPage(
                      roomId: state.roomId,
                      userId: widget.userId,
                      userName: widget.userName,
                      userProfilePic: widget.userProfilePic,
                    ),
                  ),
                );
              }
              if (state is W2GError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            buildWhen: (previous, current) =>
                current is W2GHomeLoaded || current is W2GError,
            builder: (context, state) {
              if (state is W2GError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppPallete.greyText, size: 48),
                      const SizedBox(height: 16),
                      Text(state.message, style: const TextStyle(color: AppPallete.greyText)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<W2GBloc>().add(W2GLoadRooms(userId: widget.userId)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primaryOrange),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildContent(state),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(W2GState state) {
    final activeRoom = state is W2GHomeLoaded ? state.activeRoom : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watch Together',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Watch videos with friends in real-time',
              style: TextStyle(
                color: AppPallete.greyText.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (activeRoom != null) _buildActiveRoomBanner(activeRoom),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CreateRoomBottomSheet(
                        onCreated: (name) {
                          context.read<W2GBloc>().add(W2GCreateRoom(
                            name: name,
                            createdBy: widget.userId,
                          ));
                        },
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_showJoinInput)
                  Expanded(
                    child: TextField(
                      controller: _joinCodeController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Room code (ID)',
                        hintStyle: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: AppPallete.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                if (_showJoinInput) const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_showJoinInput) {
                      final code = _joinCodeController.text.trim();
                      if (code.isEmpty) {
                        setState(() => _showJoinInput = false);
                        return;
                      }
                      context.read<W2GBloc>().add(W2GJoinRoomByCode(
                        roomId: code,
                        userId: widget.userId,
                        userName: widget.userName,
                        userProfilePic: widget.userProfilePic,
                      ));
                      _joinCodeController.clear();
                      setState(() => _showJoinInput = false);
                    } else {
                      setState(() => _showJoinInput = true);
                    }
                  },
                  icon: Icon(_showJoinInput ? Icons.arrow_forward : Icons.link),
                  label: Text(_showJoinInput ? 'Join' : 'Join by Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPallete.primaryOrange,
                    side: const BorderSide(color: AppPallete.primaryOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRoomList(state),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRoomBanner(W2GRoom room) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.primaryOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam, color: AppPallete.primaryOrange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      room.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${room.participants.length} watching',
                  style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => W2GRoomPage(
                    roomId: room.id,
                    userId: widget.userId,
                    userName: widget.userName,
                    userProfilePic: widget.userProfilePic,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Rejoin'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(W2GState state) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                'Create a room or join one\nto start watching!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
