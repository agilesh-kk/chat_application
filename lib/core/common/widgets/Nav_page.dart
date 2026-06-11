import 'dart:ui';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: widget.pages,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _buildMenuButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppPallete.cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppPallete.divider.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.menu,
              color: AppPallete.whiteColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 76,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppPallete.cardBg.withValues(alpha: 0.8),
              border: Border(
                right: BorderSide(
                  color: AppPallete.divider.withValues(alpha: 0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _switchPage(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppPallete.primaryOrange.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppPallete.primaryOrange : AppPallete.greyText,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? AppPallete.primaryOrange : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}