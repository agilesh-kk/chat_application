import 'package:flutter/material.dart';

import '../../../../core/theme/app_pallette.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _dots;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dots = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "typing",
          style: TextStyle(
            color: AppPallete.primaryOrange.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        ..._dots.map((anim) => AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Transform.translate(
                    offset: Offset(0, -2 * anim.value),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppPallete.primaryOrange
                            .withValues(alpha: 0.6 + 0.4 * anim.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            )),
      ],
    );
  }
}
