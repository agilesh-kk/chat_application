import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/pages/w2g_room_page.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/create_room_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class W2GHomePage extends StatefulWidget {
  const W2GHomePage({super.key});

  @override
  State<W2GHomePage> createState() => _W2GHomePageState();
}

class _W2GHomePageState extends State<W2GHomePage> {
  late final W2GBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = serviceLocator<W2GBloc>();
    _bloc.add(W2GLoadRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      appBar: AppBar(
        backgroundColor: AppPallete.darkBg,
        title: const Text(
          'Watch Together',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppPallete.primaryOrange),
            onPressed: () => _bloc.add(W2GLoadRooms()),
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
              _navigateToRoom(state.roomId);
            }
          },
          builder: (context, state) {
            if (state is W2GLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppPallete.primaryOrange),
              );
            }

            if (state is W2GRoomsLoaded) {
              if (state.rooms.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.rooms.length,
                itemBuilder: (context, index) {
                  final room = state.rooms[index];
                  return Card(
                    color: AppPallete.cardBg,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppPallete.divider, width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        room.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${room.participants.length} watching',
                        style: TextStyle(
                          color: AppPallete.greyText,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppPallete.primaryOrange,
                        size: 16,
                      ),
                      onTap: () => _navigateToRoom(room.id),
                    ),
                  );
                },
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppPallete.primaryOrange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => CreateRoomBottomSheet(
              onCreated: (name) {
                final userState = serviceLocator<AppUserCubit>().state;
                if (userState is AppUserIsSignedin) {
                  _bloc.add(W2GCreateRoom(
                    name: name,
                    createdBy: userState.user.id,
                  ));
                }
              },
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined,
              size: 80, color: AppPallete.greyText.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No watch rooms yet',
            style: TextStyle(
              color: AppPallete.greyText.withValues(alpha: 0.6),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a room and invite friends to watch together!',
            style: TextStyle(
              color: AppPallete.greyText.withValues(alpha: 0.4),
              fontSize: 14,
            ),
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
    );
  }
}
