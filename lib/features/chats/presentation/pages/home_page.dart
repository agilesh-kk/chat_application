import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/chats/presentation/pages/convo_page.dart';
import 'package:chat_application/features/chats/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Conversation? _selectedConvo;
  final FocusNode _keyboardFocusNode = FocusNode();

  void _onConversationSelected(Conversation convo) {
    setState(() => _selectedConvo = convo);
  }

  void _onCloseChat() {
    setState(() => _selectedConvo = null);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _selectedConvo != null) {
          _onCloseChat();
        }
      },
      child: Row(
        children: [
          SizedBox(
            width: 380,
            child: ConversationPage(
              userId: widget.userId,
              onChatSelected: _onConversationSelected,
              selectedConvoId: _selectedConvo?.convoId,
            ),
          ),
          Container(width: 1, color: AppPallete.divider),
          Expanded(
            child: _selectedConvo != null
                ? ChatPage(
                    key: ValueKey(_selectedConvo!.convoId),
                    currentUserId: widget.userId,
                    receiverId: _selectedConvo!.receiverId,
                    receiverName: _selectedConvo!.receiverName,
                    convoId: _selectedConvo!.convoId,
                    isEmbedded: true,
                    onClose: _onCloseChat,
                  )
                : _buildPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPallete.darkBg, AppPallete.darkSecondary, AppPallete.darkBg],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: ExcludeSemantics(
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
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppPallete.primaryOrange.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Select a conversation",
                    style: TextStyle(
                      color: AppPallete.greyText,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose from your existing conversations",
                    style: TextStyle(
                      color: AppPallete.greyText.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(currentUserId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      // const SizedBox(width: 10),
                      // Text(
                      //   "Find Friends",
                      //   style: TextStyle(
                      //     color: AppPallete.whiteColor,
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 16,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
