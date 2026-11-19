import '../models/order_model.dart';
import '../models/payment_model.dart';

/// Turns a list of orders into a CSV string admins can paste into Excel,
/// Google Sheets, or Numbers.
///
/// Deliberately clipboard-based rather than a file-download or
/// share-sheet plugin (see the "Copy to clipboard" flow in
/// [OrderManagementScreen]) — that works identically on Flutter Web,
/// Android and iOS with no extra dependency and no platform-specific
/// code, which matters since the admin panel runs on Flutter Web per
/// the project spec.
class CsvExportService {
  CsvExportService._();

  static const _headers = [
    'Order ID',
    'Date',
    'Restaurant',
    'Items',
    'Total (Rs.)',
    'Status',
    'Payment Method',
    'Payment Status',
    'Dispute Status',
  ];

  static String buildCsv(List<FoodOrder> orders) {
    final buffer = StringBuffer()..writeln(_headers.map(_escape).join(','));
    for (final o in orders) {
      final itemsSummary = o.items.map((i) => '${i.quantity}x ${i.menuItem.name}').join('; ');
      buffer.writeln([
        o.id,
        o.createdAt.toIso8601String(),
        o.restaurantName,
        itemsSummary,
        o.total.toStringAsFixed(0),
        o.status.label,
        o.paymentMethod.label,
        o.paymentStatus.label,
        o.disputeStatus.label,
      ].map(_escape).join(','));
    }
    return buffer.toString();
  }

  /// Quotes a field and escapes embedded quotes per RFC 4180 — needed
  /// since restaurant names and item summaries commonly contain commas.
  static String _escape(Object value) {
    final s = value.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
