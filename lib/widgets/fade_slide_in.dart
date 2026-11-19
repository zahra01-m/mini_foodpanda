import 'package:flutter/material.dart';

/// Wraps [child] in a one-shot fade + slide-up entrance animation.
///
/// Give list items an increasing [index] to get a nice staggered
/// "cascade" effect as a screen first appears.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double offset;

  /// Slide in from the side (end edge, RTL-aware) instead of from below.
  final bool horizontal;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 420),
    this.offset = 24,
    this.horizontal = false,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = _curved;

    final delay = widget.baseDelay * widget.index;
    Future.delayed(delay, () {
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
    // Respect the system "remove animations" setting.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final begin = widget.horizontal
        ? Offset(sign * 0.12, 0)
        : Offset(0, widget.offset / 100);
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(_curved),
        child: widget.child,
      ),
    );
  }
}
