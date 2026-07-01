import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/core/common/cubit/nav_page_index_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/friends/presentation/friend_requests_cubit.dart';

class NavigationPage extends StatefulWidget {
  final List<Widget> pages;

  const NavigationPage({super.key, required this.pages});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<NavPageIndexCubit>().pageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavPageIndexCubit, NavPageState>(
      listenWhen: (previous, current) => current is NavPageChanged,
      listener: (context, state) {
        if (state is NavPageChanged) {
          _pageController.jumpToPage(state.index);
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            _buildNavBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: widget.pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    final navState = context.watch<NavPageIndexCubit>().state;
    final currentIndex = navState is NavPageChanged ? navState.index : 0;

    final convoState = context.watch<ConversationBloc>().state;
    final totalUnread = convoState is ConversationLoaded
        ? convoState.conversations.fold<int>(0, (sum, c) => sum + c.unread)
        : 0;

    final reqState = context.watch<FriendRequestsCubit>().state;
    final reqCount = reqState is FriendRequestsLoaded ? reqState.requests.length : 0;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppPallete.darkTertiary,
        border: Border(
          right: BorderSide(
            color: AppPallete.divider.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavItem(currentIndex, 0, Icons.chat_bubble_outline, Icons.chat_bubble, badgeCount: totalUnread),
            const SizedBox(height: 24),
            _buildNavItem(currentIndex, 1, Icons.remove_red_eye_outlined, Icons.remove_red_eye),
            const SizedBox(height: 24),
            _buildNavItem(currentIndex, 2, Icons.person_outline, Icons.person, badgeCount: reqCount),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int currentIndex, int index, IconData outlineIcon, IconData filledIcon, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _switchPage(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSelected ? AppPallete.primaryOrange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppPallete.primaryOrange : AppPallete.greyText,
              size: 24,
            ),
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: -12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
