import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import '../core/utils/pricing.dart';

/// Subtotal / delivery / service fee / total rows.
class PriceBreakdownView extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;

  /// Promo discount already subtracted from [total]; shown as its own row.
  final double discount;
  final String promoCode;

  const PriceBreakdownView({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
    this.discount = 0,
    this.promoCode = '',
  });

  /// [b.total] is before any promo; pass [discount] to show the amount payable.
  factory PriceBreakdownView.from(PriceBreakdown b, {double discount = 0, String promoCode = ''}) =>
      PriceBreakdownView(
        subtotal: b.subtotal,
        deliveryFee: b.deliveryFee,
        serviceFee: b.serviceFee,
        total: b.total - discount,
        discount: discount,
        promoCode: promoCode,
      );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    String rs(double v) => 'Rs. ${v.toStringAsFixed(0)}';

    Widget row(String label, Widget value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(color: bold ? p.ink : p.inkSoft, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
              value,
            ],
          ),
        );

    return Column(
      children: [
        row('Subtotal', Text(rs(subtotal))),
        row(
          'Delivery fee',
          deliveryFee == 0
              ? Text('Free', style: TextStyle(color: p.success, fontWeight: FontWeight.w700))
              : Text(rs(deliveryFee)),
        ),
        row('Service fee', Text(rs(serviceFee))),
        if (discount > 0)
          row(
            promoCode.isEmpty ? 'Discount' : 'Discount ($promoCode)',
            Text('- ${rs(discount)}', style: TextStyle(color: p.success, fontWeight: FontWeight.w700)),
          ),
        const Divider(height: 16),
        row(
          'Total',
          Text(rs(total), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: p.redDeep)),
          bold: true,
        ),
      ],
    );
  }
}

/// "Add Rs. 420 more for free delivery" with a progress bar.
class FreeDeliveryBar extends StatelessWidget {
  final double subtotal;
  const FreeDeliveryBar({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unlocked = subtotal >= Pricing.freeDeliveryOver;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(unlocked ? Icons.check_circle_rounded : Icons.delivery_dining_rounded,
                  size: 18, color: unlocked ? p.success : p.redDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unlocked
                      ? 'You\'ve unlocked free delivery'
                      : 'Add Rs. ${(Pricing.freeDeliveryOver - subtotal).toStringAsFixed(0)} more for free delivery',
                  style: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (subtotal / Pricing.freeDeliveryOver).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 400),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: p.line,
                  color: p.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
