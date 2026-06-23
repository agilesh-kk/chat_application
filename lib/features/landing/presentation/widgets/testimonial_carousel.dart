import 'dart:async';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class TestimonialCarousel extends StatefulWidget {
  const TestimonialCarousel({super.key});

  @override
  State<TestimonialCarousel> createState() => _TestimonialCarouselState();
}

class _TestimonialCarouselState extends State<TestimonialCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _autoTimer;

  final List<_Testimonial> _testimonials = const [
    _Testimonial(
      name: 'Alex Rivera',
      handle: '@alexr',
      image: 'assets/profile_images/pfp1.png',
      quote:
          'Memento changed how I keep in touch. The time capsules feature helped me surprise my best friend on his birthday across time zones!',
      rating: 5,
    ),
    _Testimonial(
      name: 'Sophia Chen',
      handle: '@sophiac',
      image: 'assets/profile_images/pfp3.png',
      quote:
          'The shared timeline is beautiful. My partner and I document our memories there — it\'s like a digital scrapbook that grows every day.',
      rating: 5,
    ),
    _Testimonial(
      name: 'Marcus Johnson',
      handle: '@marcusj',
      image: 'assets/profile_images/pfp5.png',
      quote:
          'Real-time messaging with reactions and typing indicators makes conversations feel so alive. Best chat experience I\'ve had on any app.',
      rating: 5,
    ),
    _Testimonial(
      name: 'Priya Sharma',
      handle: '@priyas',
      image: 'assets/profile_images/pfp7.png',
      quote:
          'Status stories that disappear, meaningful conversations, and zero clutter. Memento respects my privacy while keeping me connected.',
      rating: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % _testimonials.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) {
              _currentPage = i;
              _startAutoScroll();
              setState(() {});
            },
            itemCount: _testimonials.length,
            itemBuilder: (context, index) {
              return _buildTestimonialCard(_testimonials[index], index);
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildTestimonialCard(_Testimonial t, int index) {
    final isCenter = index == _currentPage;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: isCenter ? 1.0 : 0.92),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCenter
                ? [
                    AppPallete.cardBg,
                    AppPallete.darkTertiary.withValues(alpha: 0.8),
                  ]
                : [
                    AppPallete.cardBg.withValues(alpha: 0.5),
                    AppPallete.darkTertiary.withValues(alpha: 0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCenter
                ? AppPallete.primaryOrange.withValues(alpha: 0.3)
                : AppPallete.divider.withValues(alpha: 0.3),
          ),
          boxShadow: isCenter
              ? [
                  BoxShadow(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(t.image, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        t.handle,
                        style: TextStyle(
                          color: AppPallete.greyText.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: i < t.rating
                          ? AppPallete.primaryOrange
                          : AppPallete.divider,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                '"${t.quote}"',
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_testimonials.length, (i) {
        final isActive = i == _currentPage;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: isActive ? 1.0 : 0.3, end: isActive ? 1.0 : 0.3),
          duration: const Duration(milliseconds: 300),
          builder: (context, opacity, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                      )
                    : null,
                color: isActive ? null : AppPallete.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Testimonial {
  final String name;
  final String handle;
  final String image;
  final String quote;
  final int rating;

  const _Testimonial({
    required this.name,
    required this.handle,
    required this.image,
    required this.quote,
    required this.rating,
  });
}
