import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/order_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/demo_data_service.dart';
import '../../widgets/admin_live_map.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/confirm_logout.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/count_up.dart';
import 'vendor_management_screen.dart';
import 'order_management_screen.dart';
import 'rider_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);
    final restaurants = ref.watch(allRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => confirmAndLogout(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Load sample data',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(restaurantServiceProvider).seedSampleData();
                final result = await DemoDataService().seedAll();
                messenger.showSnackBar(
                  SnackBar(content: Text('Sample data loaded: $result.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 8),
                    content: Text(
                      'Could not load sample data: ${friendlyError(e)} '
                      '(deploy the updated firestore.rules first)',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: orders.when(
        loading: () => const AppLoading(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load dashboard',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(allOrdersProvider),
        ),
        data: (list) {
          final revenue = list.where((o) => o.countsAsRevenue).fold<double>(0, (sum, o) => sum + o.total);
          final restaurantCount = restaurants.valueOrNull?.length ?? 0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Live orders'),
              AdminLiveMap(orders: list),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Overview'),
              Row(
                children: [
                  _StatCard(label: 'Orders', amount: list.length.toDouble()),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Vendors', amount: restaurantCount.toDouble()),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Revenue', amount: revenue, prefix: 'Rs. '),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Manage'),
              FadeSlideIn(
                index: 3,
                horizontal: true,
                child: _AdminTile(
                icon: Icons.storefront_outlined,
                label: 'Vendors',
                subtitle: 'Approve and manage restaurants & menus',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorManagementScreen())),
              ),
              ),
              FadeSlideIn(
                index: 4,
                horizontal: true,
                child: _AdminTile(
                icon: Icons.two_wheeler_outlined,
                label: 'Riders',
                subtitle: 'Approve rider sign-ups',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderManagementScreen())),
              ),
              ),
              FadeSlideIn(
                index: 5,
                horizontal: true,
                child: _AdminTile(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                subtitle: 'Monitor status, disputes & refunds',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen())),
              ),
              ),
              FadeSlideIn(
                index: 6,
                horizontal: true,
                child: _AdminTile(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                subtitle: 'Revenue and order trends',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
              ),
              ),
            ],
          );
        },
      ),
    );
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
              // FittedBox: "Rs. 1250000" must shrink, not overflow, in a 3-up row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CountUp(
                    value: amount,
                    prefix: prefix,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.redDeep),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: p.inkSoft, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: p.redDeep),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
