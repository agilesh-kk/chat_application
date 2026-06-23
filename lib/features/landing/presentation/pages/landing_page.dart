import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_in_page.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_application/features/landing/presentation/pages/friends_discovery_detail.dart';
import 'package:chat_application/features/landing/presentation/pages/rich_messaging_detail.dart';
import 'package:chat_application/features/landing/presentation/pages/shared_timeline_detail.dart';
import 'package:chat_application/features/landing/presentation/pages/status_stories_detail.dart';
import 'package:chat_application/features/landing/presentation/pages/time_capsules_detail.dart';
import 'package:chat_application/features/landing/presentation/widgets/testimonial_carousel.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _featuresController;
  late AnimationController _statsController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _heroScale;
  late Animation<double> _subtitleFade;

  late Animation<double> _featuresFade;
  late Animation<Offset> _featuresSlide;

  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;

  late Animation<double> _ctaFade;

  final ScrollController _scrollController = ScrollController();
  final List<_FeatureCardState> _featureCardStates = [];
  bool _featuresAnimTriggered = false;
  bool _statsAnimTriggered = false;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _heroScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );

    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _featuresFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _featuresController,
        curve: Curves.easeOut,
      ),
    );
    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _featuresController,
        curve: Curves.easeOutCubic,
      ),
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOut),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _statsController,
        curve: Curves.easeOutCubic,
      ),
    );

    _heroController.forward();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final viewport = _scrollController.position.viewportDimension;
    final scrollFraction = currentScroll / (maxScroll + viewport);

    if (scrollFraction > 0.18 && !_featuresAnimTriggered) {
      _featuresAnimTriggered = true;
      _featuresController.forward();
      for (final state in _featureCardStates) {
        state.triggerAnimation();
      }
    }
    if (scrollFraction > 0.55 && !_statsAnimTriggered) {
      _statsAnimTriggered = true;
      _statsController.forward();
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _featuresController.dispose();
    _statsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _registerFeatureCard(_FeatureCardState state) {
    _featureCardStates.add(state);
  }

  void _navigateToFeature(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              AppPallete.darkBg,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundDecoration(),
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 40),
                    _buildHeroSection(),
                    const SizedBox(height: 80),
                    _buildSectionHeader('Everything you need'),
                    const SizedBox(height: 8),
                    _buildSectionSubtitle(
                      'Connect, share, and stay in touch',
                    ),
                    const SizedBox(height: 32),
                    _buildFeaturesSection(),
                    const SizedBox(height: 80),
                    _buildSectionHeader('What users say'),
                    const SizedBox(height: 8),
                    _buildSectionSubtitle(
                      'Join thousands of happy users',
                    ),
                    const SizedBox(height: 32),
                    _buildTestimonialsSection(),
                    const SizedBox(height: 80),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -200,
      right: -200,
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppPallete.primaryOrange.withValues(alpha: 0.08),
              AppPallete.transparentColor,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 20,
                  color: AppPallete.whiteColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Memento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.whiteColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Column(
          children: [
            ScaleTransition(
              scale: _heroScale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppPallete.primaryOrange.withValues(alpha: 0.2),
                      AppPallete.lightOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/logo1.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
              ).createShader(bounds),
              child: const Text(
                'Memento',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.whiteColor,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                'Where moments become memories',
                style: TextStyle(
                  fontSize: 18,
                  color: AppPallete.greyText,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _ctaFade,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SignUpPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 200),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppPallete.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: AppPallete.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SignInPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 200),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.cardBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppPallete.divider,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 18,
                            color: AppPallete.primaryOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppPallete.whiteColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Container(
              width: 24,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPallete.divider,
                  width: 2,
                ),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Padding(
                    padding: EdgeInsets.only(top: 6 + value * 14),
                    child: Container(
                      width: 4,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppPallete.primaryOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 4,
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

  Widget _buildSectionSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 15,
        color: AppPallete.greyText,
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return FadeTransition(
      opacity: _featuresFade,
      child: SlideTransition(
        position: _featuresSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: _FeatureCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Rich Messaging',
                      description:
                          'Send text and images with reactions, replies, editing, and real-time typing indicators. Every conversation feels alive.',
                      delay: 0,
                      onRegister: _registerFeatureCard,
                      onTap: () => _navigateToFeature(const RichMessagingDetailPage()),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: _FeatureCard(
                      icon: Icons.remove_red_eye_outlined,
                      title: 'Status & Stories',
                      description:
                          'Share ephemeral moments that disappear. View friends stories with likes, replies, and a seamless full-screen experience.',
                      delay: 100,
                      onRegister: _registerFeatureCard,
                      onTap: () => _navigateToFeature(const StatusStoriesDetailPage()),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: _FeatureCard(
                      icon: Icons.lock_clock,
                      title: 'Time Capsules',
                      description:
                          'Schedule messages to be delivered at a future time. Perfect for birthday wishes, reminders, or surprise messages.',
                      delay: 200,
                      onRegister: _registerFeatureCard,
                      onTap: () => _navigateToFeature(const TimeCapsulesDetailPage()),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: _FeatureCard(
                      icon: Icons.favorite_outline,
                      title: 'Shared Timeline',
                      description:
                          'Build a shared timeline of memories with friends. Long-press messages to save them, and create milestone events together.',
                      delay: 300,
                      onRegister: _registerFeatureCard,
                      onTap: () => _navigateToFeature(const SharedTimelineDetailPage()),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: _FeatureCard(
                      icon: Icons.people_outline,
                      title: 'Friends & Discovery',
                      description:
                          'Find friends, send requests, and build your circle. See who is online and start conversations instantly.',
                      delay: 400,
                      onRegister: _registerFeatureCard,
                      onTap: () => _navigateToFeature(const FriendsDiscoveryDetailPage()),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return FadeTransition(
      opacity: _statsFade,
      child: SlideTransition(
        position: _statsSlide,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: TestimonialCarousel(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppPallete.divider.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 14,
                  color: AppPallete.whiteColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Memento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Built with Flutter & Firebase',
            style: TextStyle(
              fontSize: 12,
              color: AppPallete.greyText.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} Memento. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: AppPallete.greyText.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  final void Function(_FeatureCardState) onRegister;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.onRegister,
    this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _triggered = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    widget.onRegister(this);
  }

  void triggerAnimation() {
    if (_triggered) return;
    _triggered = true;
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppPallete.cardBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hovered
                        ? AppPallete.primaryOrange.withValues(alpha: 0.6)
                        : AppPallete.divider.withValues(alpha: 0.5),
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: AppPallete.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppPallete.greyText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

