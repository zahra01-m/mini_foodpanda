import '../../core/utils/error_text.dart';
import '../../core/utils/maps_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_provider.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/order_status_badge.dart';

/// The rider publishes their real GPS position to Firestore while this
/// screen is open (see [LocationService.ensureSharing]); the same
/// [LiveTrackingMap] widget the customer sees reads it back. If location
/// permission isn't available — common on an emulator — a "Simulate"
/// button glides a fake position along the route instead, so the demo
/// still works end to end.
class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ActiveDeliveryScreen({super.key, required this.orderId});

  @override
  ConsumerState<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  late final String riderId = ref.read(authProvider).user!.id;
  bool _gpsFailed = false;

  @override
  void dispose() {
    ref.read(locationServiceProvider).stopSharing();
    super.dispose();
  }

  Future<void> _startSharingFor(FoodOrder order) async {
    final ok = await ref
        .read(locationServiceProvider)
        .ensureSharing(riderId: riderId, orderId: order.id);
    if (mounted && !ok) setState(() => _gpsFailed = true);
  }

  void _simulate(FoodOrder order) {
    final headingToCustomer = order.status == OrderStatus.outForDelivery;
    ref.read(locationServiceProvider).startSimulation(
          riderId: riderId,
          orderId: order.id,
          fromLat: headingToCustomer ? order.restaurantLat : order.restaurantLat - 0.01,
          fromLng: headingToCustomer ? order.restaurantLng : order.restaurantLng - 0.01,
          toLat: headingToCustomer ? order.deliveryLat : order.restaurantLat,
          toLng: headingToCustomer ? order.deliveryLng : order.restaurantLng,
        );
    setState(() => _gpsFailed = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Active delivery')),
      body: orderAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Could not load order', subtitle: friendlyError(e)),
        data: (order) {
          if (order == null) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Order not found', subtitle: '');
          }
          if (order.status == OrderStatus.preparing || order.status == OrderStatus.outForDelivery) {
            _startSharingFor(order);
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LiveTrackingMap(
                  riderId: riderId,
                  restaurant: LatLng(order.restaurantLat, order.restaurantLng),
                  customer: LatLng(order.deliveryLat, order.deliveryLng),
                  headingToCustomer: order.status == OrderStatus.outForDelivery,
                ),
                if (_gpsFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Location permission unavailable — showing a simulated position instead.',
                            style: TextStyle(color: p.inkSoft, fontSize: 12),
                          ),
                        ),
                        TextButton(onPressed: () => _simulate(order), child: const Text('Simulate')),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.restaurantName, style: Theme.of(context).textTheme.titleLarge),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${order.items.length} items · Rs. ${order.total.toStringAsFixed(0)}',
                    style: TextStyle(color: p.inkSoft)),
                if (order.deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: p.redDeep),
                      const SizedBox(width: 6),
                      Expanded(child: Text(order.deliveryAddress)),
                    ],
                  ),
                  if (order.deliveryNote.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 24),
                      child: Text('Note: ${order.deliveryNote}',
                          style: TextStyle(color: p.inkSoft, fontStyle: FontStyle.italic)),
                    ),
                ],
                if (order.status == OrderStatus.preparing || order.status == OrderStatus.outForDelivery) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: Text(order.status == OrderStatus.preparing
                        ? 'Navigate to restaurant'
                        : 'Navigate to customer'),
                    onPressed: () async {
                      final toRestaurant = order.status == OrderStatus.preparing;
                      final ok = await openDirections(
                        lat: toRestaurant ? order.restaurantLat : order.deliveryLat,
                        lng: toRestaurant ? order.restaurantLng : order.deliveryLng,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(const SnackBar(content: Text('Could not open the Maps app.')));
                      }
                    },
                  ),
                ],
                const Spacer(),
                if (order.status == OrderStatus.preparing)
                  CustomButton(
                    label: 'Picked up — start delivery',
                    onPressed: () => ref.read(riderServiceProvider).markPickedUp(order.id),
                  )
                else if (order.status == OrderStatus.outForDelivery)
                  CustomButton(
                    label: 'Mark delivered',
                    onPressed: () async {
                      await ref.read(riderServiceProvider).markDelivered(order.id);
                      await ref.read(locationServiceProvider).stopSharing(clearRiderId: riderId);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  )
                else
                  Text('Delivered — nice work!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.success, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        },
      ),
    );
  }
}
