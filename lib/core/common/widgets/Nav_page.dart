import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class NavigationPage extends StatefulWidget {
  final List<Widget> pages;

  const NavigationPage({super.key, required this.pages});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: widget.pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
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
            _buildNavItem(0, Icons.chat_bubble_outline, Icons.chat_bubble),
            const SizedBox(height: 32),
            _buildNavItem(1, Icons.remove_red_eye_outlined, Icons.remove_red_eye),
            const SizedBox(height: 32),
            _buildNavItem(2, Icons.person_outline, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = _currentIndex == index;

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