import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/confirm_logout.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/section_header.dart';
import 'active_delivery_screen.dart';
import 'delivery_history_screen.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();
    final profile = ref.watch(userProfileProvider(user.id)).valueOrNull;
    final isApproved = profile?.isApproved ?? user.isApproved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => confirmAndLogout(context, ref),
          ),
        ],
      ),
      body: !isApproved
          ? const EmptyState(
              icon: Icons.hourglass_top_outlined,
              title: 'Waiting for approval',
              subtitle: 'An admin needs to approve your rider account before you can accept deliveries.',
            )
          : (_tab == 0 ? _RequestsTab(riderId: user.id) : DeliveryHistoryScreen(riderId: user.id, embedded: true)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Deliveries'),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final String riderId;
  const _RequestsTab({required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final active = ref.watch(activeDeliveryProvider(riderId));
    final incoming = ref.watch(incomingRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeDeliveryProvider(riderId));
        ref.invalidate(incomingRequestsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          active.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (order) {
              if (order == null) return const SizedBox();
              return Card(
                color: p.redTint,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  leading: Icon(Icons.two_wheeler, color: p.redDeep),
                  title: Text('Active delivery — ${order.restaurantName}'),
                  subtitle: Text('Rs. ${order.total.toStringAsFixed(0)} · ${order.status.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: order.id)),
                  ),
                ),
              );
            },
          ),
          const SectionHeader(title: 'Incoming requests'),
          incoming.when(
            loading: () => const SizedBox(height: 420, child: SkeletonTileList(showTrailing: true)),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load requests',
                subtitle: friendlyError(e),
                onRetry: () => ref.invalidate(incomingRequestsProvider),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No requests right now',
                    subtitle: 'New orders appear here once a restaurant starts preparing them.',
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    FadeSlideIn(
                      key: ValueKey(list[i].id),
                      index: i < 8 ? i : 0,
                      horizontal: true,
                      child: _RequestCard(order: list[i], riderId: riderId),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final FoodOrder order;
  final String riderId;
  const _RequestCard({required this.order, required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final activeAsync = ref.watch(activeDeliveryProvider(riderId));
    final hasActive = activeAsync.valueOrNull != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(order.restaurantName, style: const TextStyle(fontWeight: FontWeight.w600))),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('${order.items.length} items · Rs. ${order.total.toStringAsFixed(0)}',
                style: TextStyle(color: p.inkSoft)),
            if (order.deliveryAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(order.deliveryAddress,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(declinedRequestsProvider.notifier).update((s) => {...s, order.id});
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasActive
                        ? null
                        : () async {
                            final ok = await ref
                                .read(riderServiceProvider)
                                .acceptOrder(orderId: order.id, riderId: riderId);
                            if (!ok || !context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: order.id)),
                            );
                          },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
            if (hasActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Finish your active delivery first', style: TextStyle(color: p.inkSoft, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
