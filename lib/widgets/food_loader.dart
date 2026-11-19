import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_palette.dart';

/// Full-area loading indicator that looks like it belongs in a food app:
/// a plate-sized badge hops like a pan-flip while the dish on it keeps
/// changing (pizza, burger, ramen, ice cream...), over a shadow that
/// squashes as it lands, with a rotating "kitchen" message below.
class FoodLoader extends StatefulWidget {
  /// Fixed message. When null, [messages] are cycled.
  final String? message;
  final List<String> messages;
  final double size;

  const FoodLoader({
    super.key,
    this.message,
    this.messages = kitchenMessages,
    this.size = 64,
  });

  static const kitchenMessages = [
    'Firing up the stove…',
    'Chopping fresh ingredients…',
    'Warming the naan…',
    'Plating your food…',
  ];

  /// Used while an order is being sent.
  static const orderMessages = [
    'Sending your order to the kitchen…',
    'Telling the chef…',
    'Finding you a rider…',
    'Almost there…',
  ];

  @override
  State<FoodLoader> createState() => _FoodLoaderState();
}

class _FoodLoaderState extends State<FoodLoader> with SingleTickerProviderStateMixin {
  static const _dishes = <IconData>[
    Icons.local_pizza_rounded,
    Icons.lunch_dining_rounded,
    Icons.ramen_dining_rounded,
    Icons.icecream_rounded,
    Icons.bakery_dining_rounded,
    Icons.kebab_dining_rounded,
    Icons.rice_bowl_rounded,
    Icons.local_cafe_rounded,
  ];

  late final AnimationController _hop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  late final Timer _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    // One new dish per hop; message changes every second hop.
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = widget.size;
    final icon = _dishes[_tick % _dishes.length];
    final msg = widget.message ?? widget.messages[(_tick ~/ 2) % widget.messages.length];

    return Center(
      child: Semantics(
        liveRegion: true,
        label: msg,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: s * 2,
                height: s * 1.9,
                child: AnimatedBuilder(
                  animation: _hop,
                  builder: (context, _) {
                    final h = math.sin(math.pi * _hop.value); // 0 on the ground, 1 at the top
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Ground shadow: shrinks and fades as the plate rises.
                        Container(
                          width: s * (0.9 - 0.35 * h),
                          height: 9,
                          decoration: BoxDecoration(
                            color: p.ink.withValues(alpha: 0.14 - 0.08 * h),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Positioned(
                          bottom: 12 + s * 0.6 * h,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(1 + 0.08 * (1 - h), 1 - 0.1 * (1 - h), 1),
                            child: Container(
                              width: s,
                              height: s,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: AppColors.heroGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                child: Icon(icon, key: ValueKey(icon), color: Colors.white, size: s * 0.55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  msg,
                  key: ValueKey(msg),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny spinning pizza, for buttons and inline "busy" states where a
/// grey circular spinner would feel out of place.
class FoodSpinner extends StatefulWidget {
  final double size;
  final Color color;
  const FoodSpinner({super.key, this.size = 20, this.color = Colors.white});

  @override
  State<FoodSpinner> createState() => _FoodSpinnerState();
}

class _FoodSpinnerState extends State<FoodSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Icon(Icons.local_pizza_rounded, size: widget.size, color: widget.color),
    );
  }
}
