import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SharedTimelineDetailPage extends StatefulWidget {
  const SharedTimelineDetailPage({super.key});

  @override
  State<SharedTimelineDetailPage> createState() => _SharedTimelineDetailPageState();
}

class _SharedTimelineDetailPageState extends State<SharedTimelineDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            child: const Icon(Icons.favorite_rounded, size: 18, color: AppPallete.whiteColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupSection() {
    final events = [
      _TimelineEventData(title: 'First message share', subtitle: '2 years ago', content: 'You: Hey! How are you?', type: 'message', isLeft: true),
      _TimelineEventData(title: '100th Message 🎉', subtitle: '1 year ago', content: 'You crossed 100 messages together!', type: 'milestone', isLeft: false),
      _TimelineEventData(title: 'Saved a memory ❤️', subtitle: '6 months ago', content: 'A special moment was added to timeline', type: 'message', isLeft: true),
      _TimelineEventData(title: 'First image shared', subtitle: '3 months ago', content: 'You shared a photo together', type: 'image', isLeft: false),
    ];

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
              _buildHeader(),
              const SizedBox(height: 16),
              for (final e in events) _buildTimelineItem(e, e == events.last),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
          ),
          child: const Icon(Icons.timeline_rounded, size: 18, color: AppPallete.whiteColor),
        ),
        const SizedBox(width: 10),
        const Text(
          'Shared Timeline',
          style: TextStyle(
            color: AppPallete.whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(_TimelineEventData event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: event.isLeft
                ? Align(
                    alignment: Alignment.centerRight,
                    child: _buildBubble(event),
                  )
                : const SizedBox(),
          ),
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppPallete.divider.withValues(alpha: 0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _eventColor(event.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _eventIcon(event.type),
                    size: 12,
                    color: AppPallete.whiteColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppPallete.divider.withValues(alpha: 0.5),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          Expanded(
            child: event.isLeft
                ? const SizedBox()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBubble(event),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_TimelineEventData event) {
    final maxW = (MediaQuery.of(context).size.width * 0.38).clamp(160.0, 260.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: maxW),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: event.isLeft
              ? [AppPallete.cardBg, AppPallete.darkTertiary]
              : [AppPallete.primaryOrange.withValues(alpha: 0.3), AppPallete.lightOrange.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.primaryOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: event.isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_eventIcon(event.type), size: 14, color: AppPallete.primaryOrange),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            event.subtitle,
            style: const TextStyle(fontSize: 10, color: AppPallete.greyText),
          ),
          const SizedBox(height: 4),
          Text(
            event.content,
            softWrap: true,
            style: TextStyle(
              color: AppPallete.whiteColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'milestone':
        return Icons.star;
      default:
        return Icons.message;
    }
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'milestone':
        return AppPallete.primaryOrange;
      default:
        return AppPallete.primaryOrange;
    }
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

class _TimelineEventData {
  final String title;
  final String subtitle;
  final String content;
  final String type;
  final bool isLeft;

  const _TimelineEventData({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.type,
    required this.isLeft,
  });
}

class _Highlight {
  final IconData icon;
  final String title;
  final String desc;

  const _Highlight({required this.icon, required this.title, required this.desc});
}
