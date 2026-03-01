import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';

class SearchPage extends StatefulWidget {

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();

  void _search() {
    final name = controller.text.trim();
    if (name.isNotEmpty) {
      context.read<SearchBloc>().add(SearchStart(name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sender  = context.read<AppUserCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text("Search User")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: "Enter username",
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {

                if (state is Searching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchFound) {
                  final user = state.user;

                  // Prevent showing existing chats
                  // if (widget.existingUserIds.contains(user!.id)) {
                  //   return const Center(
                  //       child: Text("Already in chat"));
                  // }

                  return ListView(
                    children: [
                      ListTile(
                        title: Text(user!.name),
                        subtitle: Text(user.email),
                        onTap: () {
                          if(sender is AppUserIsSignedin){
                          Navigator.push(context, MaterialPageRoute(builder: (c)=>ChatPage(currentUserId: sender.user.id, receiverId: user.id, receiverName: user.name)));
                          }
                        },
                      )
                    ],
                  );
                }

                return const Center(child: Text("Search user"));
              },
            ),
          )
        ],
      ),
    );
  }
}