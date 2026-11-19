import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/eta_card.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/order_timeline.dart';
import '../../widgets/price_breakdown.dart';

/// Live order tracking, sourced from the same `orders` and
/// `riderLocations` Firestore documents the rider app writes to — any
/// status change or GPS update the rider makes appears here immediately.
class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track order'),
        actions: [
          orderAsync.maybeWhen(
            data: (order) => order == null ||
                    order.status == OrderStatus.delivered ||
                    order.disputeStatus != DisputeStatus.none
                ? const SizedBox()
                : IconButton(
                    icon: const Icon(Icons.report_gmailerrorred_outlined),
                    tooltip: 'Report a problem',
                    onPressed: () => _reportProblem(context, ref, order),
                  ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const AppLoading(message: 'Locating your order…'),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load order',
          subtitle: friendlyError(e),
        ),
        data: (order) {
          if (order == null) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Order not found', subtitle: '');
          }
          return _Body(
            order: order,
            onCancel: order.status == OrderStatus.pending ? () => _cancelOrder(context, ref, order) : null,
          );
        },
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, FoodOrder order) async {
    final cardNote = order.paymentMethod == PaymentMethod.card
        ? ' If you paid by card, an admin will review your refund.'
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text(
          'Your order from ${order.restaurantName} (Rs. ${order.total.toStringAsFixed(0)}) will be cancelled. '
          'This is only possible before the restaurant starts preparing it.$cardNote',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    try {
      await ref.read(orderServiceProvider).cancelOrder(order.id);
      messenger.showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    } on StateError {
      messenger.showSnackBar(const SnackBar(
        content: Text('The restaurant already started on this order, so it can no longer be cancelled.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _reportProblem(BuildContext context, WidgetRef ref, FoodOrder order) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a problem'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'What went wrong with this order?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await ref.read(orderServiceProvider).openDispute(order.id, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report sent — an admin will review it.')),
    );
  }
}

class _Body extends StatelessWidget {
  final FoodOrder order;
  final VoidCallback? onCancel;
  const _Body({required this.order, this.onCancel});

  bool get _active =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.preparing ||
      order.status == OrderStatus.outForDelivery;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cancelled = order.status == OrderStatus.cancelled;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id}',
                  style: TextStyle(color: p.inkSoft, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: 'Copy order ID',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_rounded, size: 18, color: p.inkSoft),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: order.id));
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('Order ID copied.')));
              },
            ),
          ],
        ),
        if (_active) ...[
          EtaCard(order: order),
          const SizedBox(height: 16),
        ],
        if ((order.status == OrderStatus.preparing || order.status == OrderStatus.outForDelivery) &&
            order.riderId != null)
          LiveTrackingMap(
            riderId: order.riderId!,
            restaurant: LatLng(order.restaurantLat, order.restaurantLng),
            customer: LatLng(order.deliveryLat, order.deliveryLng),
            headingToCustomer: order.status == OrderStatus.outForDelivery,
          )
        else
          _StatusPlaceholder(order: order),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(order.restaurantName,
                  style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            OrderStatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 16),
        if (cancelled)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: p.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('This order was cancelled.', style: TextStyle(color: p.danger))),
              ],
            ),
          )
        else
          OrderTimeline(status: order.status, placedAt: order.createdAt),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your order', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('${line.quantity}×', style: TextStyle(color: p.inkSoft)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(line.menuItem.name)),
                      Text('Rs. ${line.subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              const Divider(height: 20),
              if (order.subtotal > 0)
                PriceBreakdownView(
                  subtotal: order.subtotal,
                  deliveryFee: order.deliveryFee,
                  serviceFee: order.serviceFee,
                  total: order.total,
                  discount: order.discount,
                  promoCode: order.promoCode,
                )
              else
                // Orders placed before fees existed only have a total.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Rs. ${order.total.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: p.redDeep)),
                  ],
                ),
            ],
          ),
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel order'),
          ),
        ],
        if (order.deliveryAddress.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DeliveryDetails(order: order),
        ],
        if (order.disputeStatus != DisputeStatus.none) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: p.redDeep, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.disputeStatus.label,
                      style: TextStyle(color: p.redDeep, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusPlaceholder extends StatelessWidget {
  final FoodOrder order;
  const _StatusPlaceholder({required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final delivered = order.status == OrderStatus.delivered;
    final cancelled = order.status == OrderStatus.cancelled;
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: p.beige1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delivered
                ? Icons.check_circle_outline
                : cancelled
                    ? Icons.cancel_outlined
                    : Icons.storefront_outlined,
            size: 40,
            color: delivered ? p.success : p.inkSoft,
          ),
          const SizedBox(height: 8),
          Text(
            delivered
                ? 'Delivered — enjoy your meal!'
                : cancelled
                    ? 'Order cancelled'
                    : order.riderId == null
                        ? 'Waiting for a rider to accept'
                        : 'Rider is heading to the restaurant',
            style: TextStyle(color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetails extends StatelessWidget {
  final FoodOrder order;
  const _DeliveryDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivering to', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, size: 18, color: p.redDeep),
              const SizedBox(width: 8),
              Expanded(child: Text(order.deliveryAddress)),
            ],
          ),
          if (order.deliveryNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sticky_note_2_outlined, size: 18, color: p.inkSoft),
                const SizedBox(width: 8),
                Expanded(child: Text(order.deliveryNote, style: TextStyle(color: p.inkSoft))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
