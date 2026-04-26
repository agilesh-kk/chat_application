import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';

class SearchPage extends StatefulWidget {

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();

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
              onChanged: (value) {
                context.read<SearchBloc>().add(SearchStart(name: value.trim()));
              },
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
                  final users = state.user;

                  if (users.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () {
                          if (sender is AppUserIsSignedin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(
                                  isUser: false,
                                  user: user,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
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