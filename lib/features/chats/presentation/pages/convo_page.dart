import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationPage extends StatelessWidget {

  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appUserState = context.read<AppUserCubit>().state;
    // Trigger loading conversations when page loads
    if(appUserState is AppUserIsSignedin) {
      context.read<ConversationBloc>().add(LoadConversationsEvent(appUserState.user.id));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is ConversationLoaded) {
            final conversations = state.conversations;

            if (conversations.isEmpty) {
              return const Center(child: Text('No conversations found'));
            }

            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final convo = conversations[index];
                final isSelected = convo.convoId == state.selectedConvoId;

                return ListTile(
                  selected: isSelected,
                  title: Text(convo.convoId ?? 'Unknown'),
                  subtitle: Text(convo.lastMessage ?? ''),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    // Update selected conversation in ConversationBloc

                    // Load messages for this conversation in ChatBloc

                  },
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.add),
      //   onPressed: () {
      //     // Example: create a new conversation
      //     context
      //         .read<ConversationBloc>()
      //         .add(ConversationCreatedEvent(['userId2']));
      //   },
      // ),
    );
  }
}