import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class ConstrainedMockup extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedMockup({
    super.key,
    required this.child,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class DetailPageLayout extends StatelessWidget {
  final Widget mockup;
  final Widget content;
  final double breakpoint;

  const DetailPageLayout({
    super.key,
    required this.mockup,
    required this.content,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 4, child: mockup),
              const SizedBox(width: 48),
              Flexible(flex: 6, child: content),
            ],
          );
        }
        return Column(children: [mockup, const SizedBox(height: 40), content]);
      },
    );
  }
}

class ConstrainedCta extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedCta({super.key, required this.child, this.maxWidth = 380});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
