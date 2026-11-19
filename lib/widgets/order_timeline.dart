import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_palette.dart';
import '../models/order_model.dart';

/// Vertical delivery timeline: Placed → Preparing → On the way → Delivered.
/// Finished steps are filled, the current step pulses, and the connector
/// line fills in with an animation when the status advances.
class OrderTimeline extends StatelessWidget {
  final OrderStatus status;
  final DateTime placedAt;
  const OrderTimeline({super.key, required this.status, required this.placedAt});

  @override
  Widget build(BuildContext context) {
    final current = status.index.clamp(0, 3); // cancelled is handled by the caller
    final steps = <_Step>[
      _Step(Icons.receipt_long_rounded, 'Order placed', DateFormat('h:mm a').format(placedAt)),
      _Step(Icons.soup_kitchen_rounded, 'Preparing', current == 1 ? 'The kitchen is cooking your food' : ''),
      _Step(Icons.delivery_dining_rounded, 'On the way', current == 2 ? 'Your rider is heading to you' : ''),
      _Step(Icons.home_rounded, 'Delivered', current == 3 ? 'Enjoy your meal!' : ''),
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], done: i < current || (i == current && current == 3), active: i == current && current < 3,
              isLast: i == steps.length - 1, lineFilled: i < current),
      ],
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Step(this.icon, this.title, this.subtitle);
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool done;
  final bool active;
  final bool isLast;
  final bool lineFilled;
  const _StepRow({
    required this.step,
    required this.done,
    required this.active,
    required this.isLast,
    required this.lineFilled,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final highlight = done || active;
    return SizedBox(
      height: isLast ? 44 : 68,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 40,
                    bottom: 0,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(width: 3, color: p.line),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: lineFilled ? 1 : 0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, v, _) => FractionallySizedBox(
                            heightFactor: v,
                            child: Container(width: 3, color: p.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                _Dot(icon: step.icon, done: done, active: active),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                          color: highlight ? p.ink : p.inkSoft)),
                  if (step.subtitle.isNotEmpty)
                    Text(step.subtitle, style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final IconData icon;
  final bool done;
  final bool active;
  const _Dot({required this.icon, required this.done, required this.active});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.done ? p.success : (widget.active ? p.red : p.inkSoft);
    final filled = widget.done || widget.active;
    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Container(
                  width: 40 * (0.8 + 0.2 * _pulse.value),
                  height: 40 * (0.8 + 0.2 * _pulse.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.red.withValues(alpha: 0.25 * (1 - _pulse.value)),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  widget.done && !widget.active && widget.icon != Icons.home_rounded ? Icons.check_rounded : widget.icon,
                  size: 17,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
