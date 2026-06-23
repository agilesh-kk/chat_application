import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:flutter/material.dart';

class SharedTimelineDetailPage extends StatefulWidget {
  const SharedTimelineDetailPage({super.key});

  @override
  State<SharedTimelineDetailPage> createState() => _SharedTimelineDetailPageState();
}

class _SharedTimelineDetailPageState extends State<SharedTimelineDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _lineController;
  late AnimationController _event1Anim;
  late AnimationController _event2Anim;
  late AnimationController _event3Anim;
  late AnimationController _event4Anim;
  late AnimationController _starPulseController;
  late AnimationController _expandController;
  final ScrollController _scrollController = ScrollController();
  bool _mockupTriggered = false;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _event1Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _event2Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _event3Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _event4Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _starPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_mockupTriggered && _scrollController.position.pixels > 80) {
      _mockupTriggered = true;
      _pageController.forward();
      _lineController.forward();
      _starPulseController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 300), () => _event1Anim.forward());
      Future.delayed(const Duration(milliseconds: 600), () => _event2Anim.forward());
      Future.delayed(const Duration(milliseconds: 900), () => _event3Anim.forward());
      Future.delayed(const Duration(milliseconds: 1200), () => _event4Anim.forward());
    }
  }

  void _toggleExpand(int index) {
    if (_expandedIndex == index) {
      _expandedIndex = null;
      _expandController.reverse();
    } else {
      _expandedIndex = index;
      _expandController.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lineController.dispose();
    _event1Anim.dispose();
    _event2Anim.dispose();
    _event3Anim.dispose();
    _event4Anim.dispose();
    _starPulseController.dispose();
    _expandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPallete.darkBg, AppPallete.darkSecondary, AppPallete.darkBg],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildTopBar(),
                _buildMockupSection(),
                const SizedBox(height: 40),
                _buildTitleSection(),
                const SizedBox(height: 32),
                _buildHighlights(),
                const SizedBox(height: 40),
                _buildCTA(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppPallete.whiteColor),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
            ),
            child: const Icon(Icons.favorite_rounded, size: 18, color: AppPallete.whiteColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupSection() {
    return FadeTransition(
      opacity: _pageController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPallete.darkTertiary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPallete.divider.withValues(alpha: 0.4)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 380,
                child: Stack(
                  children: [
                    _buildTimelineLine(),
                    _buildTimelineEvents(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineLine() {
    return AnimatedBuilder(
      animation: _lineController,
      builder: (context, child) {
        return Positioned(
          left: 24,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppPallete.primaryOrange.withValues(alpha: 0.8),
                  AppPallete.lightOrange.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, child) {
                    return Container(
                      height: _lineController.value * 380,
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange.withValues(alpha: _lineController.value),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineEvents() {
    final events = [
      _TimelineEvent(
        title: 'First Met 🤝',
        subtitle: 'You & Alex became friends',
        color: const Color(0xFF4FC3F7),
        icon: Icons.people_outline,
        isStar: false,
        side: false,
      ),
      _TimelineEvent(
        title: 'Movie Night 🍿',
        subtitle: 'Watched Inception together',
        color: const Color(0xFF81C784),
        icon: Icons.movie_outlined,
        isStar: false,
        side: true,
      ),
      _TimelineEvent(
        title: '1 Year Anniversary 🎉',
        subtitle: 'Celebrated a year of friendship',
        color: const Color(0xFFFFD54F),
        icon: Icons.star_rounded,
        isStar: true,
        side: false,
      ),
      _TimelineEvent(
        title: 'Road Trip 🚗',
        subtitle: 'Weekend getaway to the mountains',
        color: const Color(0xFFCE93D8),
        icon: Icons.directions_car_outlined,
        isStar: false,
        side: true,
      ),
    ];

    final anims = [_event1Anim, _event2Anim, _event3Anim, _event4Anim];

    return Stack(
      children: List.generate(events.length, (i) {
        final e = events[i];
        return Positioned(
          top: 20.0 + i * 88.0,
          left: e.side ? null : 40,
          right: e.side ? 40 : null,
          child: _buildEventCard(e, anims[i], i),
        );
      }),
    );
  }

  Widget _buildEventCard(_TimelineEvent event, AnimationController controller, int index) {
    final isExpandedNow = _expandedIndex == index;
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(event.side ? 0.2 : -0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: controller,
        child: GestureDetector(
          onTap: () => _toggleExpand(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isExpandedNow ? 210 : 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPallete.cardBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: event.color.withValues(alpha: isExpandedNow ? 0.6 : 0.3),
              ),
              boxShadow: isExpandedNow
                  ? [BoxShadow(color: event.color.withValues(alpha: 0.15), blurRadius: 12)]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(event.icon, size: 16, color: event.color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          color: event.isStar
                              ? AppPallete.whiteColor
                              : AppPallete.greyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isExpandedNow) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.subtitle,
                    style: const TextStyle(color: AppPallete.greyText, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 12, color: AppPallete.greyText),
                      const SizedBox(width: 4),
                      Text('${12 + index * 3}', style: TextStyle(color: AppPallete.greyText, fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment_outlined, size: 12, color: AppPallete.greyText),
                      const SizedBox(width: 4),
                      Text('${3 + index}', style: TextStyle(color: AppPallete.greyText, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
            ).createShader(bounds),
            child: const Text(
              'Shared Timeline',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Build memories together',
            style: TextStyle(
              fontSize: 16,
              color: AppPallete.greyText.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    final highlights = [
      _Highlight(icon: Icons.timeline_outlined, title: 'Visual Timeline', desc: 'Beautiful scrolling timeline of shared memories'),
      _Highlight(icon: Icons.add_circle_outline, title: 'Save Moments', desc: 'Long-press any message to add it to your timeline'),
      _Highlight(icon: Icons.star_outline, title: 'Milestone Events', desc: 'Mark special moments with star milestones'),
      _Highlight(icon: Icons.palette_outlined, title: 'Colorful & Themed', desc: 'Events are color-coded by type for easy browsing'),
      _Highlight(icon: Icons.person_outline, title: 'Personal Timeline', desc: 'Keep your own private timeline too'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: highlights.map((h) => _buildHighlightRow(h)).toList(),
      ),
    );
  }

  Widget _buildHighlightRow(_Highlight h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppPallete.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(h.icon, size: 22, color: AppPallete.primaryOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title, style: const TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.w600, fontSize: 15)),
                Text(h.desc, style: TextStyle(color: AppPallete.greyText, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPallete.greyText, size: 20),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppPallete.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: AppPallete.whiteColor, size: 20),
            SizedBox(width: 10),
            Text('Get Started', style: TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isStar;
  final bool side;

  const _TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isStar,
    required this.side,
  });
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
