import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class _RestaurantStats {
  final String id;
  final String name;
  double revenue = 0;
  int orderCount = 0;
  _RestaurantStats(this.id, this.name);
}

/// Phase 4: a real fl_chart BarChart for revenue, an order-volume-by-status
/// breakdown, a top-sellers list, and a ranked restaurant leaderboard —
/// all from the same `allOrdersProvider` data source.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: orders.when(
        loading: () => const AppLoading(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load analytics',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(allOrdersProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No orders yet',
              subtitle: 'Place a test order to see revenue, status, and top-seller data here',
            );
          }

          // Cancelled and refunded orders never counted as revenue on the
          // admin dashboard's total — the chart, top items and leaderboard
          // below now agree with that instead of quietly including them.
          final revenueOrders = list.where((o) => o.countsAsRevenue).toList();

          final byRestaurant = <String, _RestaurantStats>{};
          final itemCounts = <String, int>{};
          for (final o in revenueOrders) {
            final stats = byRestaurant.putIfAbsent(o.restaurantId, () => _RestaurantStats(o.restaurantId, o.restaurantName));
            stats.revenue += o.itemsTotal; // food sales only, excluding delivery/service fees
            stats.orderCount += 1;
            for (final ci in o.items) {
              itemCounts[ci.menuItem.name] = (itemCounts[ci.menuItem.name] ?? 0) + ci.quantity;
            }
          }
          final entries = byRestaurant.values.toList();
          final maxVal = entries.isEmpty ? 1.0 : entries.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

          final byStatus = <OrderStatus, int>{};
          for (final o in list) {
            byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
          }

          final topItems = itemCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final leaderboard = [...entries]..sort((a, b) => b.revenue.compareTo(a.revenue));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Revenue by vendor'),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No completed revenue yet — every order so far was cancelled or refunded.',
                      style: TextStyle(color: p.inkSoft)),
                )
              else
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.25,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            'Rs. ${rod.toY.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= entries.length) return const SizedBox();
                              final name = entries[i].name;
                              final short = name.length > 10 ? '${name.substring(0, 9)}…' : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(short, style: TextStyle(fontSize: 10, color: p.inkSoft)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < entries.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: entries[i].revenue,
                              color: p.red,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Top restaurants'),
              if (leaderboard.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('No completed orders yet.', style: TextStyle(color: p.inkSoft)),
                )
              else
                ...List.generate(
                  leaderboard.length > 5 ? 5 : leaderboard.length,
                  (i) => _RestaurantRankTile(rank: i + 1, stats: leaderboard[i]),
                ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Orders by status'),
              ...OrderStatus.values.map((s) {
                final count = byStatus[s] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text(s.label, style: TextStyle(color: p.inkSoft))),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(height: 8, decoration: BoxDecoration(color: p.beige2, borderRadius: BorderRadius.circular(6))),
                            FractionallySizedBox(
                              widthFactor: list.isEmpty ? 0 : (count / list.length).clamp(0.0, 1.0),
                              child: Container(height: 8, decoration: BoxDecoration(color: p.redDeep, borderRadius: BorderRadius.circular(6))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$count'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Top-selling items'),
              if (topItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('No completed orders yet.', style: TextStyle(color: p.inkSoft)),
                )
              else
                ...topItems.take(5).map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.local_fire_department_outlined, color: p.redDeep),
                      title: Text(e.key),
                      trailing: Text('${e.value} sold', style: TextStyle(color: p.inkSoft)),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _RestaurantRankTile extends ConsumerWidget {
  final int rank;
  final _RestaurantStats stats;
  const _RestaurantRankTile({required this.rank, required this.stats});

  Color _medalColor(AppPalette p) {
    switch (rank) {
      case 1:
        return const Color(0xFFCBA135); // gold
      case 2:
        return const Color(0xFFA8A8A8); // silver
      case 3:
        return const Color(0xFFB08D57); // bronze
      default:
        return p.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(restaurantRatingProvider(stats.id));
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(fontWeight: FontWeight.w800, color: _medalColor(p), fontSize: 15),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stats.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${stats.orderCount} orders', style: TextStyle(color: p.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          if (rating > 0) ...[
            Icon(Icons.star_rounded, color: p.warning, size: 16),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: TextStyle(color: p.inkSoft, fontSize: 12)),
            const SizedBox(width: 10),
          ],
          Text('Rs. ${stats.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
