import 'package:flutter/material.dart';

/// A number that counts up (or down) to [value] instead of jumping.
/// On first build it counts from 0; when [value] changes later it glides
/// from the number currently shown to the new one.
class CountUp extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    // Respect the system "remove animations" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$prefix${value.toStringAsFixed(0)}$suffix', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix${v.toStringAsFixed(0)}$suffix', style: style),
    );
  }
}
