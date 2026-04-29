import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPage extends StatefulWidget {
  final String currentUserId;

  const SearchPage({super.key, required this.currentUserId});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
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
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchInput(),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state is Searching) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppPallete.primaryOrange,
                        ),
                      );
                    }

                    if (state is SearchFound) {
                      final users = state.user;

                      if (users.isEmpty) {
                        return _buildNoResults();
                      }

                      return _buildUsersList(users);
                    }

                    return _buildInitialState();
                  },
                ),
              ),
            ],
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
                'Find Friends',
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

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppPallete.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPallete.divider),
        ),
        child: TextField(
          controller: controller,
          focusNode: _focusNode,
          onChanged: (value) {
            context.read<SearchBloc>().add(SearchStart(
              name: value.trim(),
              currentUserId: widget.currentUserId,
            ));
            setState(() {});
          },
          style: TextStyle(color: AppPallete.whiteColor),
          decoration: InputDecoration(
            hintText: "Search by username...",
            hintStyle: TextStyle(color: AppPallete.greyText),
            prefixIcon: Icon(Icons.search, color: AppPallete.greyText),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
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
                Icons.person_search,
                size: 40,
                color: AppPallete.greyText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Search for friends",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter a username to find people",
              style: TextStyle(
                color: AppPallete.greyText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
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
                Icons.search_off,
                size: 40,
                color: AppPallete.greyText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No users found",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different username",
              style: TextStyle(
                color: AppPallete.greyText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(User user) {
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
                  builder: (_) => ProfilePage(
                    isUser: false,
                    user: user,
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
                      child: user.profilePic != null && user.profilePic!.isNotEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(user.profilePic!),
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
                          user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
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