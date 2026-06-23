import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/profile_image_provider.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InviteFriendsSheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String hostId;
  final String hostName;

  const InviteFriendsSheet({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.hostId,
    required this.hostName,
  });

  @override
  State<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<InviteFriendsSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsCubit = context.read<FriendsCubit>();
    final friendsState = friendsCubit.state;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppPallete.greyText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Invite Friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle:
                    TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search,
                    color: AppPallete.greyText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppPallete.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: friendsState is FriendsLoaded
                ? _buildFriendsList(friendsState.friends)
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppPallete.primaryOrange),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(Map<String, FriendModel> friends) {
    final filtered = friends.values.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.name.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: AppPallete.greyText.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No friends match your search'
                  : 'No friends to invite yet',
              style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          Divider(color: AppPallete.divider.withValues(alpha: 0.3), height: 1),
      itemBuilder: (context, index) {
        final friend = filtered[index];
        return _FriendTile(
          friend: friend,
          onTap: () {
            context.read<W2GBloc>().add(W2GInviteFriend(
              roomId: widget.roomId,
              roomName: widget.roomName,
              hostId: widget.hostId,
              hostName: widget.hostName,
              invitedUserId: friend.id,
            ));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invite sent to ${friend.name}'),
                backgroundColor: AppPallete.cardBg,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onTap;

  const _FriendTile({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppPallete.darkTertiary,
                  backgroundImage: friend.profilePic.isNotEmpty
                      ? profileImageProvider(friend.profilePic)
                      : null,
                  child: friend.profilePic.isEmpty
                      ? Text(
                          friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppPallete.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: friend.isOnline
                          ? const Color(0xFF4CAF50)
                          : AppPallete.greyText,
                      border:
                          Border.all(color: AppPallete.cardBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: friend.isOnline
                          ? const Color(0xFF4CAF50)
                          : AppPallete.greyText.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPallete.primaryOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Invite',
                style: TextStyle(
                  color: AppPallete.primaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
