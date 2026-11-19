import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:intl/intl.dart';
import '../core/theme/app_palette.dart';
import '../models/order_model.dart';

/// "Arriving in about 18–23 min" with a little scooter that rides from the
/// restaurant to your door as time passes.
///
/// The estimate is derived from kitchen time (by status) plus travel time
/// over the restaurant→delivery distance at city speed, minus the time
/// already elapsed. It refreshes every 30 s and is labelled an estimate.
class EtaCard extends StatefulWidget {
  final FoodOrder order;
  const EtaCard({super.key, required this.order});

  @override
  State<EtaCard> createState() => _EtaCardState();
}

class _EtaCardState extends State<EtaCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final p = context.palette;

    final km = Geolocator.distanceBetween(o.restaurantLat, o.restaurantLng, o.deliveryLat, o.deliveryLng) / 1000;
    final travel = (km / 20 * 60).ceil() + 3; // ~20 km/h through town + handover
    final prep = switch (o.status) {
      OrderStatus.pending => 18,
      OrderStatus.preparing => 15,
      _ => 0,
    };
    final total = prep + travel;
    final elapsed = DateTime.now().difference(o.createdAt).inMinutes;
    final isLate = elapsed > total;
    final cap = o.status == OrderStatus.outForDelivery ? travel : total;
    final left = (total - elapsed).clamp(2, cap).toInt();
    final arriveBy = DateTime.now().add(Duration(minutes: left));
    final progress = switch (o.status) {
      OrderStatus.pending => 0.04,
      OrderStatus.preparing => 0.12,
      _ => (0.3 + 0.65 * (elapsed / total)).clamp(0.3, 0.95).toDouble(),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.redTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated arrival', style: TextStyle(color: p.inkSoft, fontSize: 12)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isLate ? 'Almost there' : '$left–${left + 5} min',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: p.redDeep)),
              const Spacer(),
              Text('by ${DateFormat('h:mm a').format(arriveBy)}', style: TextStyle(color: p.inkSoft)),
            ],
          ),
          if (isLate)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Taking a little longer than usual — thanks for your patience.',
                  style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, c) {
                const icon = 28.0;
                final track = c.maxWidth - icon;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                    Positioned(left: 0, child: Icon(Icons.storefront_rounded, size: icon, color: p.redDeep)),
                    Positioned(right: 0, child: Icon(Icons.home_rounded, size: icon, color: p.redDeep)),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      left: track * progress,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: p.red, shape: BoxShape.circle),
                        child: const Icon(Icons.delivery_dining_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text('Estimate only — actual time depends on the kitchen and traffic.',
              style: TextStyle(color: p.inkSoft, fontSize: 11)),
        ],
      ),
    );
  }
}
