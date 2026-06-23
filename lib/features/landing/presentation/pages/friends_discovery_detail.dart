import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FriendsDiscoveryDetailPage extends StatefulWidget {
  const FriendsDiscoveryDetailPage({super.key});

  @override
  State<FriendsDiscoveryDetailPage> createState() => _FriendsDiscoveryDetailPageState();
}

class _FriendsDiscoveryDetailPageState extends State<FriendsDiscoveryDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _friend1Anim;
  late AnimationController _friend2Anim;
  late AnimationController _friend3Anim;
  late AnimationController _friend4Anim;
  late AnimationController _dotPulseController;
  late AnimationController _requestAnimController;
  final _focusNode = FocusNode();
  bool _requestSent = false;
  bool _isAccepted = false;
  bool _isDeclined = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _friend1Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _friend2Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _friend3Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _friend4Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _dotPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _requestAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.forward();
      _dotPulseController.repeat(reverse: true);
      _friend1Anim.forward();
      _friend2Anim.forward();
      _friend3Anim.forward();
      _friend4Anim.forward();
    });
  }

  void _sendRequest() {
    setState(() => _requestSent = true);
    _requestAnimController.forward(from: 0);
  }

  void _acceptRequest() {
    setState(() {
      _isAccepted = true;
      _isDeclined = false;
    });
  }

  void _declineRequest() {
    setState(() {
      _isAccepted = false;
      _isDeclined = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isDeclined = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _friend1Anim.dispose();
    _friend2Anim.dispose();
    _friend3Anim.dispose();
    _friend4Anim.dispose();
    _dotPulseController.dispose();
    _requestAnimController.dispose();
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
        child: Container(
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
            child: const Icon(Icons.people_rounded, size: 18, color: AppPallete.whiteColor),
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
          child: Column(
            children: [
              _buildMockupHeader(),
              const SizedBox(height: 16),
              _buildFriendList(),
              const SizedBox(height: 16),
              _buildFriendRequestCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupHeader() {
    return Row(
      children: [
        const Icon(Icons.people_outline, color: AppPallete.primaryOrange, size: 20),
        const SizedBox(width: 8),
        const Text('Friends', style: TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        GestureDetector(
          onTap: _sendRequest,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _requestSent
                  ? null
                  : const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
              color: _requestSent ? AppPallete.statusGreen : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _requestSent ? Icons.check_rounded : Icons.person_add_rounded,
                  size: 16,
                  color: AppPallete.whiteColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _requestSent ? 'Sent' : 'Add Friend',
                  style: const TextStyle(color: AppPallete.whiteColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendList() {
    final friends = [
      _MockFriend(name: 'Emma Wilson', image: 'assets/profile_images/pfp3.png', isOnline: true),
      _MockFriend(name: 'Liam Chen', image: 'assets/profile_images/pfp5.png', isOnline: true),
      _MockFriend(name: 'Ava Martinez', image: 'assets/profile_images/pfp7.png', isOnline: false),
      _MockFriend(name: 'Noah Brown', image: 'assets/profile_images/pfp9.png', isOnline: true),
    ];

    final anims = [_friend1Anim, _friend2Anim, _friend3Anim, _friend4Anim];

    return Column(
      children: List.generate(friends.length, (i) {
        return _buildFriendRow(friends[i], anims[i]);
      }),
    );
  }

  Widget _buildFriendRow(_MockFriend friend, AnimationController controller) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: controller,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppPallete.cardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPallete.divider.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(child: Image.asset(friend.image, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.name, style: const TextStyle(color: AppPallete.whiteColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      friend.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: friend.isOnline ? AppPallete.statusGreen : AppPallete.greyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _dotPulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: friend.isOnline
                          ? AppPallete.statusGreen.withValues(alpha: 0.4 + _dotPulseController.value * 0.6)
                          : AppPallete.statusGrey,
                      boxShadow: friend.isOnline
                          ? [
                              BoxShadow(
                                color: AppPallete.statusGreen.withValues(alpha: 0.2 + _dotPulseController.value * 0.3),
                                blurRadius: 4 + _dotPulseController.value * 2,
                              ),
                            ]
                          : [],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Icon(Icons.message_outlined, color: AppPallete.primaryOrange, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAccepted
            ? AppPallete.statusGreen.withValues(alpha: 0.1)
            : _isDeclined
                ? Colors.redAccent.withValues(alpha: 0.1)
                : AppPallete.darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAccepted
              ? AppPallete.statusGreen.withValues(alpha: 0.3)
              : _isDeclined
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : AppPallete.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPallete.primaryOrange.withValues(alpha: 0.4), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset('assets/profile_images/pfp11.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sarah Kim', style: TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Mutual friends: 3', style: TextStyle(color: AppPallete.greyText, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isAccepted && !_isDeclined)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _declineRequest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppPallete.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPallete.divider),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                          SizedBox(width: 6),
                          Text('Decline', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _acceptRequest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 16, color: AppPallete.whiteColor),
                          SizedBox(width: 6),
                          Text('Accept', style: TextStyle(color: AppPallete.whiteColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _isAccepted ? AppPallete.statusGreen : Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAccepted ? 'Friend request accepted!' : 'Request declined',
                  style: TextStyle(
                    color: _isAccepted ? AppPallete.statusGreen : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
        ],
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
              'Friends & Discovery',
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
            'Find and connect with people',
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
      _Highlight(icon: Icons.person_search_outlined, title: 'Find Friends', desc: 'Search for users and discover new connections'),
      _Highlight(icon: Icons.person_add_outlined, title: 'Send Requests', desc: 'Send friend requests with a single tap'),
      _Highlight(icon: Icons.checklist_outlined, title: 'Manage Requests', desc: 'Accept or decline incoming friend requests'),
      _Highlight(icon: Icons.circle_outlined, title: 'Online Presence', desc: 'See who\'s online with live status indicators'),
      _Highlight(icon: Icons.chat_outlined, title: 'Instant Chat', desc: 'Start conversations with friends instantly'),
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

class _MockFriend {
  final String name;
  final String image;
  final bool isOnline;

  const _MockFriend({required this.name, required this.image, required this.isOnline});
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
