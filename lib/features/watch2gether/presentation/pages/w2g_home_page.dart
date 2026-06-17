import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/pages/w2g_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class W2GHomePage extends StatefulWidget {
  const W2GHomePage({super.key});

  @override
  State<W2GHomePage> createState() => _W2GHomePageState();
}

class _W2GHomePageState extends State<W2GHomePage> {
  late final W2GBloc _bloc;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _bloc = serviceLocator<W2GBloc>();
    final userState = serviceLocator<AppUserCubit>().state;
    if (userState is AppUserIsSignedin) {
      _currentUserId = userState.user.id;
    }
    _bloc.add(W2GLoadRooms(userId: _currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      appBar: AppBar(
        backgroundColor: AppPallete.darkBg,
        title: const Text(
          'Watch Together',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppPallete.primaryOrange),
            onPressed: () => _bloc.add(W2GLoadRooms(userId: _currentUserId)),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<W2GBloc, W2GState>(
          listener: (context, state) {
            if (state is W2GError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppPallete.errorColor,
                ),
              );
            }
            if (state is W2GRoomCreated) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => W2GRoomPage(roomId: state.roomId),
                ),
              ).then((_) => _bloc.add(W2GLoadRooms(userId: _currentUserId)));
            }
          },
          builder: (context, state) {
            if (state is W2GLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppPallete.primaryOrange),
              );
            }

            if (state is W2GHomeLoaded) {
              if (state.activeRoom != null) {
                return _buildActiveRoom(state.activeRoom!);
              }
              return _buildCreateJoinUi();
            }

            if (state is W2GRoomLoaded) {
              return _buildActiveRoom(state.room);
            }

            return _buildCreateJoinUi();
          },
        ),
      ),
    );
  }

  Widget _buildActiveRoom(W2GRoom room) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 100, color: AppPallete.primaryOrange.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(room.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${room.participants.length} watching', style: TextStyle(color: AppPallete.greyText, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToRoom(room.id),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Enter Room', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateJoinUi() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined, size: 80, color: AppPallete.greyText.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Watch Together',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a room and invite friends to watch together',
              style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.6), fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add),
                label: const Text('Create Room', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createRoom() {
    _showCreateDialog();
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.cardBg,
        title: const Text('Create Room', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Room name',
            hintStyle: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppPallete.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppPallete.greyText))),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              _bloc.add(W2GCreateRoom(name: name, createdBy: _currentUserId));
            },
            child: const Text('Create', style: TextStyle(color: AppPallete.primaryOrange)),
          ),
        ],
      ),
    );
  }

  void _navigateToRoom(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => W2GRoomPage(roomId: roomId),
      ),
    ).then((_) => _bloc.add(W2GLoadRooms(userId: _currentUserId)));
  }
}
