import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/chats/presentation/pages/search_page.dart';
import 'package:chat_application/features/chats/presentation/widgets/convo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';

class ConversationPage extends StatefulWidget {
  final String userId;

  const ConversationPage({super.key, required this.userId});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  bool isSearching = false;
  bool _isSearchVisible = false;
  final _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;
  late Animation<double> _searchWidthAnimation;

  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>()
        .add(LoadConversationsEvent(widget.userId));
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeOut),
    );
    
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && isSearching && searchController.text.isEmpty) {
        _toggleSearch();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      isSearching = _isSearchVisible;
    });
    
    if (_isSearchVisible) {
      _searchAnimationController.forward();
      _searchFocusNode.requestFocus();
    } else {
      _searchAnimationController.reverse();
      searchController.clear();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchAnimationController.dispose();
    _searchFocusNode.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              Expanded(
                child: BlocBuilder<ConversationBloc, ConversationState>(
                  builder: (context, state) {
                    if (state is ConversationLoading) {
                      return const Center(child: Loader());
                    }

                    if (state is ConversationLoaded) {
                      var conversations = state.conversations;
                      
                      if (isSearching && searchController.text.isNotEmpty) {
                        final query = searchController.text.toLowerCase();
                        conversations = conversations.where((c) => 
                          c.receiverName.toLowerCase().contains(query) ||
                          c.lastMessage.toLowerCase().contains(query)
                        ).toList();
                      }
                      
                      if (conversations.isEmpty) {
                        return isSearching ? _buildNoResultsState() : _buildEmptyState();
                      }

                      return _buildChatList(conversations);
                    }

                    if (state is ConversationError) {
                      return _buildErrorState(state.message);
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildChatList(List conversations) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final convo = conversations[index];
        return ConvoTile(
          unread: convo.unread,
          name: convo.receiverName, 
          lastMessage: convo.lastMessage, 
          profilePic: convo.profilepicLink, 
          lastUpdateTime: convo.lastupdateTime,
          lastSender: convo.lastSender == widget.userId ? "you" : "",
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c)=>ChatPage(currentUserId: widget.userId, receiverId: convo.receiverId, receiverName: convo.receiverName, convoId: convo.convoId,)));
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchAnimationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SizedBox(
            height: 50,
            child: Stack(
              children: [
                if (_isSearchVisible)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width * _searchWidthAnimation.value,
                      decoration: BoxDecoration(
                        color: AppPallete.inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPallete.divider),
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            isSearching = value.isNotEmpty;
                          });
                        },
                        style: TextStyle(color: AppPallete.whiteColor),
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          hintStyle: TextStyle(color: AppPallete.greyText),
                          prefixIcon: Icon(Icons.search, color: AppPallete.greyText),
                          suffixIcon: isSearching
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppPallete.greyText),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      isSearching = false;
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.close, color: AppPallete.greyText),
                                  onPressed: _toggleSearch,
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _toggleSearch,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPallete.inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPallete.divider),
                        ),
                        child: Icon(
                          Icons.search,
                          color: AppPallete.greyText,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Chats",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  letterSpacing: -1,
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
          BlocBuilder<ConversationBloc, ConversationState>(
            builder: (context, state) {
              int totalChats = 0;
              int unreadCount = 0;
              if (state is ConversationLoaded) {
                totalChats = state.conversations.length;
                unreadCount = state.conversations.fold(0, (sum, c) => sum + c.unread);
              }
              return _buildStatsBadge(totalChats, unreadCount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(int totalChats, int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPallete.cardBg,
            AppPallete.darkTertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$totalChats",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "Chats",
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 30,
            color: AppPallete.divider,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "$unreadCount",
                    style: TextStyle(
                      color: unreadCount > 0 ? AppPallete.primaryOrange : AppPallete.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppPallete.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                "Unread",
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppPallete.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(currentUserId: widget.userId,)));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.edit,
                color: AppPallete.whiteColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
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
              "No results found",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try a different search term",
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppPallete.primaryOrange.withValues(alpha: 0.3),
                        AppPallete.lightOrange.withValues(alpha: 0.1),
                        AppPallete.primaryOrange.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppPallete.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPallete.primaryOrange.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppPallete.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "No chats yet",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start a new conversation",
              style: TextStyle(
                color: AppPallete.greyText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(currentUserId: widget.userId,)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, color: AppPallete.whiteColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Find Friends",
                      style: TextStyle(
                        color: AppPallete.whiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppPallete.cardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppPallete.errorColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: AppPallete.errorColor,
              ),
              const SizedBox(height: 20),
              Text(
                "Something went wrong",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}