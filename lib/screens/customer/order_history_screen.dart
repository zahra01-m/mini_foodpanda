import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/reorder.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/skeleton_list.dart';
import 'order_tracking_screen.dart';
import 'rate_review_screen.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

enum _OrderFilter { all, active, past }

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  static bool _isActive(FoodOrder o) =>
      o.status == OrderStatus.pending ||
      o.status == OrderStatus.preparing ||
      o.status == OrderStatus.outForDelivery;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: EmptyState(icon: Icons.lock_outline, title: 'Not logged in', subtitle: 'Log in to see your orders'));
    }
    final orders = ref.watch(customerOrdersProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.when(
        loading: () => const SkeletonTileList(showTrailing: true),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load orders',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(customerOrdersProvider(user.id)),
        ),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your placed orders will show up here',
              retryLabel: 'Browse restaurants',
              retryIcon: Icons.storefront_rounded,
              onRetry: () => Navigator.pop(context),
            );
          }
          final list = switch (_filter) {
            _OrderFilter.all => all,
            _OrderFilter.active => all.where(_isActive).toList(),
            _OrderFilter.past => all.where((o) => !_isActive(o)).toList(),
          };
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<_OrderFilter>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _OrderFilter.all, label: Text('All')),
                    ButtonSegment(value: _OrderFilter.active, label: Text('Active')),
                    ButtonSegment(value: _OrderFilter.past, label: Text('Past')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (v) => setState(() => _filter = v.first),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _filter == _OrderFilter.active ? 'No active orders' : 'No past orders',
                        subtitle: 'Nothing to show here right now.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, i) => FadeSlideIn(
                          key: ValueKey(list[i].id),
                          index: i < 8 ? i : 0,
                          baseDelay: const Duration(milliseconds: 45),
                          child: _OrderCard(order: list[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final FoodOrder order;
  const _OrderCard({required this.order});

  bool get _active =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.preparing ||
      order.status == OrderStatus.outForDelivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final reviewedIds = ref.watch(reviewedOrderIdsProvider(order.customerId)).valueOrNull ?? const <String>{};
    final canRate = order.status == OrderStatus.delivered && !reviewedIds.contains(order.id);
    final summary = order.items.map((i) => '${i.quantity}× ${i.menuItem.name}').join(', ');

    void track() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
        );

    // Material (not a coloured Container) sits under the InkWell so the tap
    // ripple is actually visible — it was painted underneath the opaque
    // Container before, so order cards gave no touch feedback.
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: p.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
        child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: track,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.restaurantName,
                        style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(DateFormat('MMM d · h:mm a').format(order.createdAt),
                  style: TextStyle(color: p.inkSoft, fontSize: 12)),
              const SizedBox(height: 10),
              Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Rs. ${order.total.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.redDeep)),
                  const SizedBox(width: 8),
                  Text('· ${order.paymentStatus.label}',
                      style: TextStyle(
                          fontSize: 12,
                          color: order.paymentStatus == PaymentStatus.succeeded ? p.success : p.inkSoft)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canRate)
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => RateReviewScreen(order: order))),
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Rate'),
                    ),
                  const Spacer(),
                  if (_active)
                    FilledButton.icon(
                      onPressed: track,
                      icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                      label: const Text('Track order'),
                    )
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      onPressed: () => reorder(context, ref, order),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Order again'),
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
