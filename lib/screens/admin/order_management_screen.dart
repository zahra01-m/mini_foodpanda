import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../providers/order_provider.dart';
import '../../services/csv_export_service.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/fade_slide_in.dart';

enum _DateFilter { all, today, thisWeek, custom }

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  OrderStatus? _statusFilter;
  _DateFilter _dateFilter = _DateFilter.all;
  DateTimeRange? _customRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _statusFilter != null || _dateFilter != _DateFilter.all;

  List<FoodOrder> _applyFilters(List<FoodOrder> all) {
    final range = _resolvedRange();
    final q = _query.trim().toLowerCase();
    return all.where((o) {
      if (_statusFilter != null && o.status != _statusFilter) return false;
      if (range != null) {
        final day = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
        if (day.isBefore(range.start) || day.isAfter(range.end)) return false;
      }
      if (q.isNotEmpty) {
        final matchesName = o.restaurantName.toLowerCase().contains(q);
        final matchesId = o.id.toLowerCase().contains(q);
        if (!matchesName && !matchesId) return false;
      }
      return true;
    }).toList();
  }

  /// Normalizes the active date filter to a whole-day [start, end] range.
  DateTimeRange? _resolvedRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case _DateFilter.all:
        return null;
      case _DateFilter.today:
        return DateTimeRange(start: today, end: today);
      case _DateFilter.thisWeek:
        return DateTimeRange(start: today.subtract(Duration(days: today.weekday - 1)), end: today);
      case _DateFilter.custom:
        if (_customRange == null) return null;
        return DateTimeRange(
          start: DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day),
          end: DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day),
        );
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _dateFilter = _DateFilter.custom;
    });
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _statusFilter = null;
      _dateFilter = _DateFilter.all;
      _customRange = null;
    });
  }

  String get _dateFilterLabel {
    switch (_dateFilter) {
      case _DateFilter.all:
        return 'Any date';
      case _DateFilter.today:
        return 'Today';
      case _DateFilter.thisWeek:
        return 'This week';
      case _DateFilter.custom:
        final r = _customRange;
        if (r == null) return 'Custom';
        String two(int n) => n.toString().padLeft(2, '0');
        return '${two(r.start.month)}/${two(r.start.day)} – ${two(r.end.month)}/${two(r.end.day)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(allOrdersProvider);
    final filtered = orders.maybeWhen(data: _applyFilters, orElse: () => const <FoodOrder>[]);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, filtered),
          ),
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by restaurant or order id',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('All statuses'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                for (final s in OrderStatus.values) ...[
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _statusFilter == s,
                    onSelected: (_) => setState(() => _statusFilter = _statusFilter == s ? null : s),
                  ),
                  const SizedBox(width: 8),
                ],
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 15),
                  label: Text(_dateFilterLabel),
                  onPressed: () async {
                    final choice = await showMenu<_DateFilter>(
                      context: context,
                      position: const RelativeRect.fromLTRB(200, 160, 16, 0),
                      items: const [
                        PopupMenuItem(value: _DateFilter.all, child: Text('Any date')),
                        PopupMenuItem(value: _DateFilter.today, child: Text('Today')),
                        PopupMenuItem(value: _DateFilter.thisWeek, child: Text('This week')),
                        PopupMenuItem(value: _DateFilter.custom, child: Text('Custom range…')),
                      ],
                    );
                    if (choice == null) return;
                    if (choice == _DateFilter.custom) {
                      await _pickCustomRange();
                    } else {
                      setState(() => _dateFilter = choice);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: orders.when(
              loading: () => const SkeletonTileList(showTrailing: true),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load orders',
                subtitle: friendlyError(e),
                onRetry: () => ref.invalidate(allOrdersProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    subtitle: 'Orders placed by customers will show up here',
                  );
                }
                final list = _applyFilters(all);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No orders match',
                    subtitle: 'Try a different search or clear your filters.',
                    retryLabel: 'Clear filters',
                    onRetry: _clearFilters,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final o = list[i];
                    return FadeSlideIn(
index: i < 8 ? i : 0,
horizontal: true,
child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(child: Text(o.restaurantName)),
                          if (o.disputeStatus == DisputeStatus.open)
                            Icon(Icons.report_problem_outlined, size: 16, color: p.warning),
                        ],
                      ),
                      subtitle: Text(
                        'Rs. ${o.total.toStringAsFixed(0)} · ${o.items.length} items · ${o.paymentStatus.label}',
                      ),
                      onTap: () => _showDetail(context, ref, o),
                      trailing: DropdownButton<OrderStatus>(
                        value: o.status,
                        underline: const SizedBox(),
                        items: OrderStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: OrderStatusBadge(status: s)))
                            .toList(),
                        onChanged: (s) {
                          if (s == null) return;
                          ref.read(orderServiceProvider).updateStatus(o.id, s);
                        },
                      ),
                    ),
);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, FoodOrder o) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.restaurantName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Rs. ${o.total.toStringAsFixed(0)} · ${o.paymentMethod.label} · ${o.paymentStatus.label}',
                style: TextStyle(color: p.inkSoft)),
            const SizedBox(height: 12),
            for (final item in o.items)
              Text('${item.quantity} × ${item.menuItem.name}', style: TextStyle(color: p.inkSoft)),
            if (o.subtotal > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Food Rs. ${o.subtotal.toStringAsFixed(0)} · Delivery Rs. ${o.deliveryFee.toStringAsFixed(0)} · Service Rs. ${o.serviceFee.toStringAsFixed(0)}',
                style: TextStyle(color: p.inkSoft, fontSize: 12),
              ),
            ],
            if (o.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Deliver to: ${o.deliveryAddress}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (o.deliveryNote.isNotEmpty) Text('Note: ${o.deliveryNote}', style: TextStyle(color: p.inkSoft)),
            ],
            const SizedBox(height: 16),
            if (o.disputeStatus == DisputeStatus.open) ...[
              Text('Dispute: ${o.disputeReason}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(orderServiceProvider).resolveDispute(orderId: o.id, refund: false);
                        Navigator.pop(context);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(orderServiceProvider).resolveDispute(orderId: o.id, refund: true);
                        Navigator.pop(context);
                      },
                      child: const Text('Accept & refund'),
                    ),
                  ),
                ],
              ),
            ] else if (o.paymentStatus == PaymentStatus.succeeded)
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(orderServiceProvider).refund(o.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Issue refund'),
              ),
          ],
        ),
      ),
    );
  }

  /// Exports whatever the current search/status/date filters show — so
  /// exporting "today's cancelled orders" is just filter, then export.
  Future<void> _exportCsv(BuildContext context, List<FoodOrder> orders) async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to export with the current filters.')),
      );
      return;
    }
    final csv = CsvExportService.buildCsv(orders);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export ${orders.length} orders'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied CSV for ${orders.length} orders — paste into Excel or Sheets.')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copy to clipboard'),
          ),
        ],
      ),
    );
  }
}
