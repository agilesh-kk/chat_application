import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/functions/helper_functions.dart';
import 'package:chat_application/features/status/presentation/pages/add_status_page.dart';
import 'package:chat_application/features/status/presentation/pages/view_status_page.dart';
import 'package:chat_application/features/status/presentation/widgets/friends_status_card.dart';
import 'package:chat_application/features/status/presentation/widgets/user_status_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool hasStatus=false;
  @override
  void initState() {
    super.initState();
    context.read<StatusBloc>().add(GetAllStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    if (appUserState is! AppUserIsSignedin) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String currentUserName = appUserState.user.name;
    final String currentUserId = appUserState.user.id;
    final String? pfp = appUserState.user.profilePic;
    //print(appUserState.user.friends);
    //print(username);

    return Scaffold(
      appBar: AppBar(title: Text("Status")),
      body: BlocConsumer<StatusBloc, StatusState>(
        listener: (context, state) {
          if(state is StatusFailure){
            showSnackbar(context, state.error.toString());
          }
        },
        builder: (context, state) {
          if(state is StatusLoading){
            return const Loader();
          }
          if(state is StatusDisplaySuccess){
            //grouping all the status posted by the same user
            final Map<String, List<Status>> groupedStatuses = {};

            final friends = appUserState.user.friends;

            for (var st in state.status) {
              if (st.userId == currentUserId) continue;
              // filtering non friends
              if (!friends!.contains(st.userId)) continue;

              if (!groupedStatuses.containsKey(st.userId)) {
                groupedStatuses[st.userId] = [];
              }

              groupedStatuses[st.userId]!.add(st);
            }

            final users = groupedStatuses.keys.toList();

            final myStatuses = state.status
              .where((st) => st.userId == currentUserId)
              .toList();
            final bool hasStatus = myStatuses.isNotEmpty;
            // print(hasStatus);
            // print(pfp);

            return RefreshIndicator(
              onRefresh: () async{ //refreshing the page.
                context.read<StatusBloc>().add(GetAllStatusEvent());
                context.read<AuthBloc>().add(AuthCheckRequested());
              },
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserStatusColumn(
                      name: currentUserName,
                      image: pfp,
                      hasStatus: hasStatus,

                      //to view the user's status
                      onViewStatus: ()async {
                        bool hasInternet = await HelperFunctions.hasInternet();
                        if (myStatuses.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewStatusPage(
                                statuses: myStatuses,
                                isUserStatus: true,
                                hasInternet: hasInternet,
                                userProfilePic: pfp!,
                                //isUserStatus: true,
                              ),
                            ),
                          );
                        }
                      },

                      // adding status
                      onAddStatus: () async {

                        bool hasInternet = await HelperFunctions.hasInternet();

                        if(!hasInternet && context.mounted){
                          showSnackbar(context, "Need Internet to Upload Status");
                          return;
                        }

                        XFile? res = await HelperFunctions.showImageSourceBottomSheet(
                          currentUserId,
                          context,
                        );

                        if (!context.mounted || res == null) {
                          return;
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<StatusBloc>(),
                              child: AddStatusPage(
                                userId: currentUserId,
                                image: res,
                                userName: currentUserName,
                              ),
                            ),
                          ),
                        );
                        
                        context.read<StatusBloc>().add(GetAllStatusEvent());
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Friends",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {

                            final userId = users[index];
                            final userStatuses = groupedStatuses[userId]!;

                            final firstStatus = userStatuses.first;

                            return FriendsStatusCard(
                              status: firstStatus,
                              onstatusTap: () {
                                userStatuses.sort(
                                  (a, b) => a.createdAt.compareTo(b.createdAt),
                                );
                                for(final status in userStatuses){
                                  context.read<StatusBloc>().add(
                                    UpdateViewEvent(
                                      statusId: status.id,
                                      viewerId: currentUserId,
                                      viewerName: currentUserName,
                                      //viewedAt: DateTime.now().toUtc(),
                                    )
                                  );
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewStatusPage(
                                      statuses: userStatuses,
                                      isUserStatus: false,
                                      hasInternet: false,
                                      userProfilePic: firstStatus.profilepic,
                                    ),
                                  ),
                                );
                              },
                              latestStatusTime: userStatuses.first.createdAt.toString(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
