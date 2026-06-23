import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_application/core/common/cubit/nav_page_index_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

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
            _buildNavItem(currentIndex, 0, Icons.chat_bubble_outline, Icons.chat_bubble),
            const SizedBox(height: 24),
            _buildNavItem(currentIndex, 1, Icons.remove_red_eye_outlined, Icons.remove_red_eye),
            const SizedBox(height: 24),
            _buildNavItem(currentIndex, 2, Icons.videocam_outlined, Icons.videocam),
            const SizedBox(height: 24),
            _buildNavItem(currentIndex, 3, Icons.person_outline, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int currentIndex, int index, IconData outlineIcon, IconData filledIcon) {
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
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          color: isSelected ? AppPallete.primaryOrange : AppPallete.greyText,
          size: 24,
        ),
      ),
    );
  }
}
