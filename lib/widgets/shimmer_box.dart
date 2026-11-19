import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

/// A single shimmering placeholder block — the building unit for the
/// skeleton loading screens in `skeleton_list.dart`. Sweeps a soft
/// highlight left-to-right on a loop, so a loading list reads as
/// "content is on its way" rather than a blank pause before a spinner.
///
/// Colours follow the theme: in dark mode the old fixed beige tones
/// flashed bright cream blocks on a near-black screen.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? p.line : p.beige2;
    final highlight = isDark ? const Color(0xFF4A3C2D) : p.beige1;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Slides the gradient's begin/end alignment across the box every
        // cycle — the moving highlight band between the two base-color
        // stops is what reads as a "shimmer" sweep.
        final t = _controller.value;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
                begin: Alignment(-3 + t * 6, 0),
                end: Alignment(-1 + t * 6, 0),
              ),
            ),
          ),
        );
      },
    );
  }
}
