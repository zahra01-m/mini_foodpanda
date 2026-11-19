import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/rider_provider.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/count_up.dart';

/// Delivery history + earnings summary for a rider. Used both as the
/// "Deliveries" tab inside [RiderHomeScreen] (embedded, no AppBar) and
/// as a standalone pushed screen if it's ever linked to from elsewhere.
class DeliveryHistoryScreen extends ConsumerWidget {
  final String riderId;
  final bool embedded;

  const DeliveryHistoryScreen({super.key, required this.riderId, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(riderHistoryProvider(riderId));
    final earnings = ref.watch(riderEarningsProvider(riderId));
    final dateFmt = DateFormat('MMM d, h:mm a');
    final p = context.palette;

    final body = RefreshIndicator(
      onRefresh: () async => ref.invalidate(riderHistoryProvider(riderId)),
      child: history.when(
        loading: () => const SkeletonTileList(showTrailing: true),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load deliveries',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(riderHistoryProvider(riderId)),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'Earnings'),
            Row(
              children: [
                _StatCard(label: 'Total earned', amount: earnings, prefix: 'Rs. '),
                const SizedBox(width: 12),
                _StatCard(label: 'Deliveries', amount: list.length.toDouble()),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'History'),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No deliveries yet',
                  subtitle: 'Completed deliveries and their earnings will show up here.',
                ),
              )
            else
              ...list.asMap().entries.map((e) => FadeSlideIn(
                    index: e.key < 8 ? e.key : 0,
                    horizontal: true,
                    child: Builder(builder: (context) {
                      final o = e.value;
                      return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline, color: p.success),
                      title: Text(o.restaurantName),
                      subtitle: Text(dateFmt.format(o.createdAt)),
                      trailing: Text('Rs. ${(o.total * 0.12).toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: p.redDeep)),
                    ),
                  );
                    }),
                  )),
          ],
        ),
      ),
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Deliveries')), body: body);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String prefix;
  const _StatCard({required this.label, required this.amount, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CountUp(
                  value: amount,
                  prefix: prefix,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.redDeep)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: p.inkSoft, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
