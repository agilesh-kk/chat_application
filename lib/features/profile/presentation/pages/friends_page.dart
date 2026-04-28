import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  Stream<List<FriendModel>> _getFriendsStream() {
    final friendsCubit = context.watch<FriendsCubit>();
    if (friendsCubit.state is FriendsLoaded) {
      return (friendsCubit.state as FriendsLoaded).friends;
    }
    return const Stream.empty();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUserState = context.read<AppUserCubit>().state;
      if (appUserState is AppUserIsSignedin) {
        context.read<FriendsCubit>().loadFriends(userId: appUserState.user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    if (appUserState is! AppUserIsSignedin) {
      return Scaffold(
        backgroundColor: AppPallete.darkBg,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppPallete.primaryOrange,
          ),
        ),
      );
    }

    final currentUser = appUserState.user;

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
          child: StreamBuilder<List<FriendModel>>(
            stream: _getFriendsStream(),
            builder: (context, snapshot) {
              final friends = snapshot.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                  if (friends.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final friend = friends[index];
                          return _buildFriendTile(
                            context,
                            friend: friend,
                            currentUserId: currentUser.id,
                          );
                        },
                        childCount: friends.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    'Friends',
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppPallete.greyText,
          ),
          const SizedBox(height: 16),
          Text(
            "No friends yet",
            style: TextStyle(
              fontSize: 18,
              color: AppPallete.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation to add friends",
            style: TextStyle(
              fontSize: 14,
              color: AppPallete.greyText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(
    BuildContext context, {
    required FriendModel friend,
    required String currentUserId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPallete.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    currentUserId: currentUserId,
                    receiverId: friend.id,
                    receiverName: friend.name,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppPallete.primaryOrange.withValues(alpha: 0.6),
                          AppPallete.lightOrange.withValues(alpha: 0.3),
                          AppPallete.primaryOrange.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPallete.cardBg,
                      ),
                      child: friend.profilePic.isNotEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(friend.profilePic),
                              backgroundColor: AppPallete.cardBg,
                            )
                          : Icon(
                              Icons.person,
                              color: AppPallete.greyText,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          friend.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppPallete.greyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppPallete.primaryOrange,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}