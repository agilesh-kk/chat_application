import 'dart:async';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeCapsulesDetailPage extends StatefulWidget {
  const TimeCapsulesDetailPage({super.key});

  @override
  State<TimeCapsulesDetailPage> createState() => _TimeCapsulesDetailPageState();
}

class _TimeCapsulesDetailPageState extends State<TimeCapsulesDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _capsulePulseController;
  late AnimationController _scheduleAnimController;
  late AnimationController _card1Anim;
  late AnimationController _card2Anim;
  late AnimationController _card3Anim;
  final _focusNode = FocusNode();

  final DateTime _targetDate = DateTime.now().add(const Duration(days: 3, hours: 14, minutes: 30));
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _capsulePulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scheduleAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _card1Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card2Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _card3Anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _updateRemaining();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.forward();
      _capsulePulseController.repeat(reverse: true);
      _card1Anim.forward();
      _card2Anim.forward();
      _card3Anim.forward();

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemaining();
        if (mounted) setState(() {});
      });
    });
  }

  void _updateRemaining() {
    _remaining = _targetDate.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  void _showScheduleAnimation() {
    _scheduleAnimController.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _scheduleAnimController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _capsulePulseController.dispose();
    _scheduleAnimController.dispose();
    _card1Anim.dispose();
    _card2Anim.dispose();
    _card3Anim.dispose();
    _countdownTimer?.cancel();
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
            child: const Icon(Icons.lock_clock_rounded, size: 18, color: AppPallete.whiteColor),
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
              _buildCapsuleHeader(),
              const SizedBox(height: 20),
              _buildCountdownClock(),
              const SizedBox(height: 24),
              _buildScheduledCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _capsulePulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + _capsulePulseController.value * 0.08,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1 + _capsulePulseController.value * 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.1 + _capsulePulseController.value * 0.15),
                      blurRadius: 20 + _capsulePulseController.value * 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_clock_rounded, size: 28, color: AppPallete.primaryOrange),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time Capsule', style: TextStyle(color: AppPallete.whiteColor, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Message scheduled for the future', style: TextStyle(color: AppPallete.greyText, fontSize: 12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showScheduleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('+ New', style: TextStyle(color: AppPallete.whiteColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownClock() {
    _updateRemaining();
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.divider.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeUnit(days, 'Days'),
          _buildTimeSeparator(),
          _buildTimeUnit(hours, 'Hours'),
          _buildTimeSeparator(),
          _buildTimeUnit(minutes, 'Mins'),
          _buildTimeSeparator(),
          _buildTimeUnit(seconds, 'Secs'),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            value.toString().padLeft(2, '0'),
            key: ValueKey(value),
            style: const TextStyle(
              color: AppPallete.whiteColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(label, style: const TextStyle(color: AppPallete.greyText, fontSize: 11)),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedBuilder(
        animation: _capsulePulseController,
        builder: (context, child) {
          return Text(
            ':',
            style: TextStyle(
              color: AppPallete.primaryOrange.withValues(alpha: 0.5 + _capsulePulseController.value * 0.5),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduledCards() {
    final capsules = [
      _ScheduledCapsule(
        title: 'Happy Birthday! 🎂',
        recipient: 'To: Mom',
        time: DateTime.now().add(const Duration(days: 30)),
        icon: Icons.cake_outlined,
      ),
      _ScheduledCapsule(
        title: 'Good luck with exam!',
        recipient: 'To: Sarah',
        time: DateTime.now().add(const Duration(days: 7, hours: 12)),
        icon: Icons.school_outlined,
      ),
      _ScheduledCapsule(
        title: 'Congratulations 🎉',
        recipient: 'To: Alex',
        time: DateTime.now().add(const Duration(days: 14)),
        icon: Icons.celebration_outlined,
      ),
    ];

    return Column(
      children: List.generate(capsules.length, (i) {
        final controllers = [_card1Anim, _card2Anim, _card3Anim];
        return _buildCapsuleCard(capsules[i], controllers[i]);
      }),
    );
  }

  Widget _buildCapsuleCard(_ScheduledCapsule capsule, AnimationController controller) {
    final remaining = capsule.time.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: controller,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppPallete.cardBg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.divider.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(capsule.icon, size: 20, color: AppPallete.primaryOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(capsule.title, style: const TextStyle(color: AppPallete.whiteColor, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(capsule.recipient, style: TextStyle(color: AppPallete.greyText, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${days}d ${hours}h',
                  style: const TextStyle(color: AppPallete.primaryOrange, fontSize: 12, fontWeight: FontWeight.w600),
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
              'Time Capsules',
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
            'Send messages to the future',
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
      _Highlight(icon: Icons.schedule_send_outlined, title: 'Schedule Messages', desc: 'Pick any future date and time for delivery'),
      _Highlight(icon: Icons.lock_outlined, title: 'Sealed Until Delivery', desc: 'Messages remain hidden until the scheduled time'),
      _Highlight(icon: Icons.notifications_outlined, title: 'Delivery Notification', desc: 'Both sender and receiver get notified on delivery'),
      _Highlight(icon: Icons.event_outlined, title: 'Perfect for Occasions', desc: 'Birthdays, anniversaries, or surprise messages'),
      _Highlight(icon: Icons.list_alt_outlined, title: 'Manage Capsules', desc: 'View, edit, or cancel your scheduled messages'),
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

class _ScheduledCapsule {
  final String title;
  final String recipient;
  final DateTime time;
  final IconData icon;

  const _ScheduledCapsule({
    required this.title,
    required this.recipient,
    required this.time,
    required this.icon,
  });
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
