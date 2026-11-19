import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  /// Status colours come from the brightness-aware palette so the badge
  /// stays legible in dark mode (the old fixed light-mode colours such as
  /// the deep brown "Preparing" were nearly invisible on a dark surface).
  Color _color(AppPalette p) {
    switch (status) {
      case OrderStatus.pending:
        return p.warning;
      case OrderStatus.preparing:
        return p.redDeep;
      case OrderStatus.outForDelivery:
        return p.red;
      case OrderStatus.delivered:
        return p.success;
      case OrderStatus.cancelled:
        return p.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context.palette);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OrderStatus.outForDelivery || status == OrderStatus.preparing)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: _Pulse(color: color),
            ),
          Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Color color;
  const _Pulse({required this.color});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}
