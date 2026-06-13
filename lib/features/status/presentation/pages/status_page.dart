import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/functions/helper_functions.dart';
import 'package:chat_application/features/status/presentation/pages/add_status_page.dart';
import 'package:chat_application/features/status/presentation/models/user_status_batch.dart';
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

class _StatusPageState extends State<StatusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appUserState = context.read<AppUserCubit>().state;
      if (appUserState is AppUserIsSignedin) {
        context.read<StatusBloc>().add(GetAllStatusEvent(currentUserId: appUserState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    final String currentUserName = appUserState.user.name;
    final String currentUserId = appUserState.user.id;
    final String? pfp = appUserState.user.profilePic;

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
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<StatusBloc, StatusState>(
            listener: (context, state) {
              if (state is StatusFailure) {
                showSnackbar(context, state.error.toString());
              }
            },
            builder: (context, state) {
              if (state is StatusLoading) {
                return const Loader();
              }
              if (state is StatusDisplaySuccess) {
                final Map<String, List<Status>> groupedStatuses = {};
                final friends = appUserState.user.friends;

                for (var st in state.status) {
                  if (st.userId == currentUserId) continue;
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

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<StatusBloc>().add(GetAllStatusEvent(currentUserId: currentUserId));
                      context.read<AuthBloc>().add(AuthCheckRequested());
                    },
                    color: AppPallete.primaryOrange,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: UserStatusColumn(
                              name: currentUserName,
                              image: pfp,
                              hasStatus: hasStatus,
                              onViewStatus: () async {
                                if (myStatuses.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ViewStatusPage(
                                        userStatusBatches: [
                                          UserStatusBatch(
                                            userId: currentUserId,
                                            userName: currentUserName,
                                            profilePic: pfp ?? '',
                                            statuses: myStatuses,
                                          ),
                                        ],
                                        hasInternet: true,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onAddStatus: () async {
                                XFile? res =
                                    await HelperFunctions.showImageSourceBottomSheet(
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

                                context
                                    .read<StatusBloc>()
                                    .add(GetAllStatusEvent(currentUserId: currentUserId));
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSectionHeader('Friends'),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final userId = users[index];
                              final userStatuses = groupedStatuses[userId]!;
                              userStatuses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: FriendsStatusCard(
                                  statuses: userStatuses,
                                  onstatusTap: () {
                                    final batches = users.map((uid) {
                                      final sts = groupedStatuses[uid]!;
                                      sts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                                      return UserStatusBatch(
                                        userId: uid,
                                        userName: sts.first.userName,
                                        profilePic: sts.first.profilepic,
                                        statuses: sts,
                                      );
                                    }).toList();

                                    final startBatchIndex = users.indexOf(userId);
                                    final tappedBatch = batches[startBatchIndex];
                                    final firstUnviewedIndex = tappedBatch.statuses
                                        .indexWhere((s) => !s.isViewed);
                                    final startStatusIndex = firstUnviewedIndex == -1 ? 0 : firstUnviewedIndex;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewStatusPage(
                                          userStatusBatches: batches,
                                          startBatchIndex: startBatchIndex,
                                          startStatusIndex: startStatusIndex,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: users.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppPallete.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppPallete.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
}
