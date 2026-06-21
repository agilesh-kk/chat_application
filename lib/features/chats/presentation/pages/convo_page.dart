import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/presentation/cubit/convo_typing_cubit.dart';
import 'package:chat_application/features/chats/presentation/cubit/notification_details_cubit.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/chats/presentation/pages/search_page.dart';
import 'package:chat_application/features/chats/presentation/widgets/convo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationPage extends StatefulWidget {
  final String userId;
  final void Function(Conversation)? onChatSelected;
  final String? selectedConvoId;

  const ConversationPage({
    super.key,
    required this.userId,
    this.onChatSelected,
    this.selectedConvoId,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _searchSlide;
  late Animation<Offset> _tilesSlide;
  final searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>()
        .add(LoadConversationsEvent(widget.userId));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      await checkIfOpenedfromNotification();
    },);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _searchSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOutCubic),
    ));
    _tilesSlide = Tween<Offset>(
      begin: const Offset(0.3, 0), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
    ));
    _animationController.forward();
  }

  Future<void> checkIfOpenedfromNotification()async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final receiverName = prefs.getString("sender_name") ?? '';
    final receiverId = prefs.getString("sender_id") ?? '';

    if(receiverId.isNotEmpty && mounted){
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(currentUserId: widget.userId, receiverId: receiverId, receiverName: receiverName),));
      await prefs.remove("sender_id");
      await prefs.remove("sender_name");
    }
  }

  void _subscribeToTyping(List conversations) {
    final cubit = context.read<ConvoTypingCubit>();
    for (final convo in conversations) {
      cubit.subscribeToTyping(convo.convoId, convo.receiverId);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    _searchFocusNode.dispose();
    final state = context.read<ConversationBloc>().state;
    if (state is ConversationLoaded) {
      final cubit = context.read<ConvoTypingCubit>();
      for (final convo in state.conversations) {
        cubit.unsubscribeFromTyping(convo.convoId);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppPallete.darkBg,
        //floatingActionButton: _buildFAB(),
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: _buildHeader(context),
                ),
                SlideTransition(
                  position: _searchSlide,
                  child: _buildSearchBar(),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _tilesSlide,
                    child: BlocListener<ConversationBloc, ConversationState>(
                  listenWhen: (previous, current) => current is ConversationLoaded,
                  listener: (context, state) {
                    if (state is ConversationLoaded) {
                      _subscribeToTyping(state.conversations);
                    }
                  },
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

  Widget _buildChatList(List conversations) {
    return BlocBuilder<ConvoTypingCubit, Map<String, bool>>(
      builder: (context, typingMap) {
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
              isOnline: convo.receiverIsOnline,
              isTyping: typingMap[convo.convoId] == true,
              draft: convo.draft,
              isSelected: convo.convoId == widget.selectedConvoId,
              onTap: () {
                _searchFocusNode.unfocus();
                if (widget.onChatSelected != null) {
                  widget.onChatSelected!(convo);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>ChatPage(currentUserId: widget.userId, receiverId: convo.receiverId, receiverName: convo.receiverName, convoId: convo.convoId,)));
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 50,
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
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
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
                  fontSize: 28,
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

  // Widget _buildFAB() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 90),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
  //         ),
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [
  //           BoxShadow(
  //             color: AppPallete.primaryOrange.withValues(alpha: 0.4),
  //             blurRadius: 20,
  //             offset: const Offset(0, 8),
  //           ),
  //         ],
  //       ),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(16),
  //           onTap: () {
  //             _searchFocusNode.unfocus();
  //             Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(currentUserId: widget.userId,)));
  //           },
  //           child: Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Icon(
  //               Icons.edit,
  //               color: AppPallete.whiteColor,
  //               size: 24,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
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
                    padding: const EdgeInsets.all(24),
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
                      size: 40,
                      color: AppPallete.primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "No chats yet",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Start a new conversation",
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(currentUserId: widget.userId,)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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