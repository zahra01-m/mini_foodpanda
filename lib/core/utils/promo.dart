import 'pricing.dart';

/// A discount code. Eligibility and the discount amount are computed here
/// only, from the order's own price breakdown, so the checkout screen and
/// [OrderService.placeOrder] can never disagree (the UI sends just the code,
/// never an amount).
///
/// NOTE: codes are defined in the app, which is fine for a demo. A real
/// launch should validate them server-side (e.g. a Cloud Function).
class PromoCode {
  final String code;
  final String title;
  final double percentOff;
  final double maxDiscount;
  final bool freeDelivery;
  final double minSubtotal;

  const PromoCode({
    required this.code,
    required this.title,
    this.percentOff = 0,
    this.maxDiscount = double.infinity,
    this.freeDelivery = false,
    this.minSubtotal = 0,
  });

  /// `null` when the code can be used on [price]; otherwise the reason it can't.
  String? ineligibleReason(PriceBreakdown price) {
    if (price.subtotal < minSubtotal) {
      return 'Add Rs. ${(minSubtotal - price.subtotal).toStringAsFixed(0)} more to use $code.';
    }
    if (freeDelivery && percentOff == 0 && price.deliveryFee == 0) {
      return 'Delivery is already free on this order.';
    }
    return null;
  }

  /// Rupees taken off [price]; 0 when the code doesn't apply.
  double discountFor(PriceBreakdown price) {
    if (ineligibleReason(price) != null) return 0;
    var d = 0.0;
    if (freeDelivery) d += price.deliveryFee;
    if (percentOff > 0) {
      final pct = (price.subtotal * percentOff / 100).roundToDouble();
      d += pct > maxDiscount ? maxDiscount : pct;
    }
    return d > price.total ? price.total : d;
  }
}

class PromoCodes {
  PromoCodes._();

  static const List<PromoCode> all = [
    PromoCode(code: 'WELCOME10', title: '10% off (up to Rs. 300) on orders over Rs. 500', percentOff: 10, maxDiscount: 300, minSubtotal: 500),
    PromoCode(code: 'FOODIE15', title: '15% off (up to Rs. 250) on orders over Rs. 800', percentOff: 15, maxDiscount: 250, minSubtotal: 800),
    PromoCode(code: 'FREESHIP', title: 'Free delivery on orders over Rs. 300', freeDelivery: true, minSubtotal: 300),
  ];

  /// Case-insensitive lookup; `null` for an unknown code.
  static PromoCode? lookup(String? input) {
    final c = (input ?? '').trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final p in all) {
      if (p.code == c) return p;
    }
    return null;
  }

  /// The discount for [code] on [price] (0 if the code is empty / unknown / not eligible).
  static double discountFor(String? code, PriceBreakdown price) => lookup(code)?.discountFor(price) ?? 0;
}
