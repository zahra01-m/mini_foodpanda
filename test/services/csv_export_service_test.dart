import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/cart_item_model.dart';
import 'package:mini_foodpanda/models/menu_item_model.dart';
import 'package:mini_foodpanda/models/order_model.dart';
import 'package:mini_foodpanda/models/payment_model.dart';
import 'package:mini_foodpanda/services/csv_export_service.dart';

void main() {
  const menuItem = MenuItem(id: 'm1', restaurantId: 'r1', name: 'Karahi', description: '', price: 900);
  final items = [const CartItem(menuItem: menuItem, quantity: 2)];

  FoodOrder order({
    String id = 'order-1',
    String restaurantName = 'Karahi House',
    OrderStatus status = OrderStatus.delivered,
  }) {
    return FoodOrder(
      id: id,
      customerId: 'cust-1',
      restaurantId: 'r1',
      restaurantName: restaurantName,
      items: items,
      total: 1800,
      status: status,
      paymentStatus: PaymentStatus.succeeded,
      createdAt: DateTime(2026, 3, 1, 12, 30),
    );
  }

  group('CsvExportService.buildCsv', () {
    test('starts with the expected header row', () {
      final csv = CsvExportService.buildCsv([order()]);
      final lines = csv.trim().split('\n');
      expect(
        lines.first,
        'Order ID,Date,Restaurant,Items,Total (Rs.),Status,Payment Method,Payment Status,Dispute Status',
      );
    });

    test('writes one row per order with the item summary and total', () {
      final csv = CsvExportService.buildCsv([order(), order(id: 'order-2', restaurantName: 'Slice Street')]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // header + 2 orders
      expect(lines[1], contains('order-1'));
      expect(lines[1], contains('2x Karahi'));
      expect(lines[1], contains('1800'));
      expect(lines[2], contains('order-2'));
    });

    test('quotes a restaurant name that contains a comma', () {
      final csv = CsvExportService.buildCsv([order(restaurantName: 'Karahi, House & Grill')]);
      expect(csv, contains('"Karahi, House & Grill"'));
    });

    test('escapes an embedded double quote by doubling it', () {
      final csv = CsvExportService.buildCsv([order(restaurantName: 'The "Best" Karahi')]);
      expect(csv, contains('"The ""Best"" Karahi"'));
    });

    test('produces just the header row for an empty order list', () {
      final csv = CsvExportService.buildCsv(const []);
      expect(csv.trim().split('\n'), hasLength(1));
    });
  });
}
