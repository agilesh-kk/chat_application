import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/chats/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';

class ConversationPage extends StatelessWidget {
  final String userId;

  const ConversationPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {

    context.read<ConversationBloc>()
        .add(LoadConversationsEvent(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(),));
            },
          )
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {

          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConversationLoaded) {
            final conversations = state.conversations;

            if (conversations.isEmpty) {
              return const Center(child: Text("No chats yet"));
            }

            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final convo = conversations[index];

                return ListTile(
                  title: Text(convo.receiverName),
                  subtitle: Text(convo.lastMessage ?? ""),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c)=>ChatPage(currentUserId: userId, receiverId: convo.receiverId, receiverName: convo.receiverName, convoId: convo.convoId,)));
                  },
                );
              },
            );
          }

          if (state is ConversationError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}