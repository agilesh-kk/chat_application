import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusStoriesDetailPage extends StatefulWidget {
  const StatusStoriesDetailPage({super.key});

  @override
  State<StatusStoriesDetailPage> createState() => _StatusStoriesDetailPageState();
}

class _StatusStoriesDetailPageState extends State<StatusStoriesDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _ringsController;
  late AnimationController _ring1Anim;
  late AnimationController _ring2Anim;
  late AnimationController _ring3Anim;
  late AnimationController _ring4Anim;
  late AnimationController _ring5Anim;
  late AnimationController _storyOverlayController;
  late AnimationController _likeAnimController;
  final _focusNode = FocusNode();
  bool _showStoryOverlay = false;
  bool _isLiked = false;
  int _currentStoryIndex = 0;

  final List<_StoryUser> _users = const [
    _StoryUser(name: 'Your Story', image: 'assets/profile_images/pfp1.png', hasStory: false),
    _StoryUser(name: 'Emma', image: 'assets/profile_images/pfp3.png', hasStory: true),
    _StoryUser(name: 'Liam', image: 'assets/profile_images/pfp5.png', hasStory: true),
    _StoryUser(name: 'Ava', image: 'assets/profile_images/pfp7.png', hasStory: true),
    _StoryUser(name: 'Noah', image: 'assets/profile_images/pfp9.png', hasStory: true),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _ringsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring1Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring2Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring3Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring4Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ring5Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _storyOverlayController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _likeAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    for (final c in [_ring1Anim, _ring2Anim, _ring3Anim, _ring4Anim, _ring5Anim]) {
      c.addListener(() => setState(() {}));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.forward();
      _ringsController.forward();
      _ring1Anim.repeat();
      _ring2Anim.repeat();
      _ring3Anim.repeat();
      _ring4Anim.repeat();
      _ring5Anim.repeat();
    });
  }

  void _openStory(int index) {
    if (index == 0) return;
    _currentStoryIndex = index;
    setState(() => _showStoryOverlay = true);
    _storyOverlayController.forward(from: 0);
    _isLiked = false;
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    _likeAnimController.forward(from: 0);
  }

  void _nextStory() {
    if (_currentStoryIndex < _users.length - 1) {
      setState(() => _currentStoryIndex++);
      _isLiked = false;
    } else {
      _closeStory();
    }
  }

  void _closeStory() {
    _storyOverlayController.reverse().then((_) {
      setState(() => _showStoryOverlay = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ringsController.dispose();
    _ring1Anim.dispose();
    _ring2Anim.dispose();
    _ring3Anim.dispose();
    _ring4Anim.dispose();
    _ring5Anim.dispose();
    _storyOverlayController.dispose();
    _likeAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            Container(
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
                  child: Column(
                    children: [
                      _buildTopBar(),
                      _buildMockupSection(),
                      const SizedBox(height: 40),
                      _buildTitleSection(),
                      const SizedBox(height: 32),
                      _buildHighlights(),
                    ],
                  ),
                ),
              ),
            ),
            if (_showStoryOverlay) _buildStoryOverlay(),
          ],
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
            child: const Icon(Icons.remove_red_eye_rounded, size: 18, color: AppPallete.whiteColor),
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppPallete.darkTertiary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPallete.divider.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_users.length, (i) => _buildStoryRing(i)),
              ),
              const SizedBox(height: 24),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppPallete.cardBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Tap a friend\'s ring to view their story',
                    style: TextStyle(color: AppPallete.greyText, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryRing(int index) {
    final user = _users[index];
    final anims = [_ring1Anim, _ring2Anim, _ring3Anim, _ring4Anim, _ring5Anim];
    final ringAnim = anims[index];

    return GestureDetector(
      onTap: () => _openStory(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user.hasStory
                  ? SweepGradient(
                      colors: [
                        AppPallete.storyGradientStart,
                        AppPallete.storyGradientEnd,
                        AppPallete.storyGradientStart,
                      ],
                      transform: GradientRotation(ringAnim.value * 6.28),
                    )
                  : null,
              color: user.hasStory ? null : AppPallete.divider,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppPallete.darkBg),
              child: ClipOval(
                child: Image.asset(user.image, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            style: TextStyle(
              color: index == 0 ? AppPallete.primaryOrange : AppPallete.greyText,
              fontSize: 11,
              fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryOverlay() {
    final user = _users[_currentStoryIndex];
    return FadeTransition(
      opacity: _storyOverlayController,
      child: GestureDetector(
        onTap: _closeStory,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < 0) { _nextStory(); }
            else if (_currentStoryIndex > 0) {
              setState(() => _currentStoryIndex--);
              _isLiked = false;
            }
          }
        },
        child: Container(
          color: AppPallete.darkBg,
          child: Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppPallete.whiteColor),
                        onPressed: _closeStory,
                      ),
                      const Spacer(),
                      Text(user.name, style: const TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.more_vert_rounded, color: AppPallete.greyText),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppPallete.storyGradientStart.withValues(alpha: 0.3),
                        AppPallete.storyGradientEnd.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(user.image, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sunset vibes 🌅',
                          style: TextStyle(color: AppPallete.whiteColor, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '2 hours ago',
                          style: TextStyle(color: AppPallete.whiteColor.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _toggleLike,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                              CurvedAnimation(parent: _likeAnimController, curve: Curves.elasticOut),
                            ),
                            child: Icon(
                              _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              size: 48,
                              color: _isLiked ? Colors.redAccent : AppPallete.whiteColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLiked ? 'Liked!' : 'Tap to like',
                          style: TextStyle(color: AppPallete.greyText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _closeStory,
                        icon: const Icon(Icons.reply_rounded, color: AppPallete.primaryOrange, size: 20),
                        label: const Text('Reply', style: TextStyle(color: AppPallete.primaryOrange)),
                      ),
                      Text(
                        '${_currentStoryIndex + 1} / ${_users.length - 1}',
                        style: const TextStyle(color: AppPallete.greyText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              'Status & Stories',
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
            'Share moments that disappear',
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
      _Highlight(icon: Icons.camera_alt_outlined, title: 'Photo Status', desc: 'Share photos with captions that disappear'),
      _Highlight(icon: Icons.visibility_outlined, title: 'Full-Screen View', desc: 'Immersive story viewing experience'),
      _Highlight(icon: Icons.favorite_outline, title: 'Like & Reply', desc: 'React to stories and start conversations'),
      _Highlight(icon: Icons.people_outline, title: 'Friends Stories', desc: 'See all your friends\' stories in one feed'),
      _Highlight(icon: Icons.timer_outlined, title: 'Ephemeral', desc: 'Stories automatically expire after a set time'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: highlights.map((h) => SizedBox(
              width: isWide ? (constraints.maxWidth - 16) / 2 : double.infinity,
              child: _buildHighlightCard(h),
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHighlightCard(_Highlight h) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPallete.divider.withValues(alpha: 0.5)),
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
            child: Icon(h.icon, size: 28, color: AppPallete.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(h.title, style: const TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(h.desc, style: TextStyle(color: AppPallete.greyText, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

}

class _StoryUser {
  final String name;
  final String image;
  final bool hasStory;

  const _StoryUser({required this.name, required this.image, required this.hasStory});
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
