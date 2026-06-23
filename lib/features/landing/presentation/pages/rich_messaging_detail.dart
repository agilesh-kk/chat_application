import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:flutter/material.dart';

class RichMessagingDetailPage extends StatefulWidget {
  const RichMessagingDetailPage({super.key});

  @override
  State<RichMessagingDetailPage> createState() =>
      _RichMessagingDetailPageState();
}

class _RichMessagingDetailPageState extends State<RichMessagingDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _mockupController;
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  late AnimationController _bubble3Controller;
  late AnimationController _bubble4Controller;
  late AnimationController _typingController;
  late AnimationController _reactionController;
  final ScrollController _scrollController = ScrollController();
  bool _mockupTriggered = false;
  bool _showReaction = false;

  @override
  void initState() {
    super.initState();
    _mockupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bubble1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bubble2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bubble3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bubble4Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_mockupTriggered && _scrollController.position.pixels > 80) {
      _mockupTriggered = true;
      _mockupController.forward();
      Future.delayed(const Duration(milliseconds: 200), () => _bubble1Controller.forward());
      Future.delayed(const Duration(milliseconds: 500), () => _bubble2Controller.forward());
      Future.delayed(const Duration(milliseconds: 800), () => _bubble3Controller.forward());
      Future.delayed(const Duration(milliseconds: 1100), () => _bubble4Controller.forward());
      Future.delayed(const Duration(milliseconds: 1400), () => _typingController.repeat(reverse: true));
    }
  }

  void _toggleReaction() {
    if (_showReaction) {
      _reactionController.reverse();
    } else {
      _reactionController.forward();
    }
    _showReaction = !_showReaction;
  }

  @override
  void dispose() {
    _mockupController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    _typingController.dispose();
    _reactionController.dispose();
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
              gradient: LinearGradient(
                colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
              ),
            ),
            child: const Icon(Icons.chat_bubble_rounded, size: 18, color: AppPallete.whiteColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupSection() {
    return FadeTransition(
      opacity: _mockupController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 380,
          decoration: BoxDecoration(
            color: AppPallete.darkTertiary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPallete.divider.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildMockupHeader(),
              const Divider(color: AppPallete.divider, height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      _buildChatBubbles(),
                      if (_showReaction)
                        Positioned(
                          left: 40,
                          top: 60,
                          child: FadeTransition(
                            opacity: _reactionController,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.3, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _reactionController,
                                  curve: Curves.elasticOut,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppPallete.darkBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppPallete.divider),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _EmojiReaction(emoji: '❤️', isSelected: false),
                                    SizedBox(width: 4),
                                    _EmojiReaction(emoji: '😂', isSelected: true),
                                    SizedBox(width: 4),
                                    _EmojiReaction(emoji: '😮', isSelected: false),
                                    SizedBox(width: 4),
                                    _EmojiReaction(emoji: '👍', isSelected: false),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      _buildReplyPreview(),
                    ],
                  ),
                ),
              ),
              _buildMockupInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPallete.primaryOrange.withValues(alpha: 0.3),
            ),
            child: const Icon(Icons.person, size: 16, color: AppPallete.primaryOrange),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alex', style: TextStyle(color: AppPallete.whiteColor, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Online', style: TextStyle(color: AppPallete.statusGreen, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppPallete.statusGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubbles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimatedBubble(
          controller: _bubble1Controller,
          text: 'Hey! Want to grab coffee later?',
          isMine: false,
          delay: 0,
        ),
        const SizedBox(height: 8),
        _AnimatedBubble(
          controller: _bubble2Controller,
          text: 'Sure! How about 3pm?',
          isMine: true,
          delay: 0,
        ),
        const SizedBox(height: 8),
        _AnimatedBubble(
          controller: _bubble3Controller,
          text: 'Perfect! See you at Brew House ☕',
          isMine: false,
          delay: 0,
          onTap: _toggleReaction,
        ),
        const SizedBox(height: 8),
        _AnimatedBubble(
          controller: _bubble4Controller,
          text: 'Can\'t wait! 😊',
          isMine: true,
          delay: 0,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _buildTypingIndicator(),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, child) {
                        final phase = (_typingController.value * 2 + i * 0.5) % 1.0;
                        final scale = 0.4 + 0.6 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPallete.greyText,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _mockupController,
            curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppPallete.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPallete.primaryOrange.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.reply_rounded, size: 14, color: AppPallete.primaryOrange),
              const SizedBox(width: 6),
              Text('Replying to "Perfect!"', style: TextStyle(color: AppPallete.primaryOrange, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.inputBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: AppPallete.greyText, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppPallete.darkTertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppPallete.greyText, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.send_rounded, color: AppPallete.primaryOrange, size: 22),
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
              'Rich Messaging',
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
            'Conversations that feel alive',
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
      _Highlight(icon: Icons.chat_bubble_outline, title: 'Text & Images', desc: 'Send rich messages with full image support'),
      _Highlight(icon: Icons.emoji_emotions_outlined, title: 'Reactions & Replies', desc: 'React with emojis and swipe to reply'),
      _Highlight(icon: Icons.edit_outlined, title: 'Edit & Delete', desc: 'Edit sent messages or delete for everyone'),
      _Highlight(icon: Icons.keyboard_alt_outlined, title: 'Typing Indicators', desc: 'See when someone is typing in real-time'),
      _Highlight(icon: Icons.visibility_outlined, title: 'Read Receipts', desc: 'Know when your messages are read'),
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
            Icon(Icons.chat_bubble_rounded, color: AppPallete.whiteColor, size: 20),
            SizedBox(width: 10),
            Text('Get Started', style: TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBubble extends StatelessWidget {
  final AnimationController controller;
  final String text;
  final bool isMine;
  final int delay;
  final VoidCallback? onTap;

  const _AnimatedBubble({
    required this.controller,
    required this.text,
    required this.isMine,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(isMine ? 0.2 : -0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: controller,
        child: GestureDetector(
          onTap: onTap,
          child: Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange])
                    : null,
                color: isMine ? null : AppPallete.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMine ? AppPallete.whiteColor : AppPallete.greyText,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiReaction extends StatelessWidget {
  final String emoji;
  final bool isSelected;

  const _EmojiReaction({required this.emoji, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? AppPallete.primaryOrange.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: TextStyle(fontSize: isSelected ? 22 : 18)),
    );
  }
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
