/// Delivery / service fee rules in one place so the cart, checkout,
/// order placement and tracking screens always agree.
///
/// These are app-wide constants for now. To make them per-restaurant,
/// add fields to `Restaurant` and pass them into [Pricing.of].
class Pricing {
  Pricing._();

  static const double deliveryFee = 80;
  static const double freeDeliveryOver = 1500;
  static const double serviceFeeRate = 0.03;
  static const double minimumOrder = 200;

  static PriceBreakdown of(double subtotal) {
    final delivery = (subtotal <= 0 || subtotal >= freeDeliveryOver) ? 0.0 : deliveryFee;
    final service = (subtotal * serviceFeeRate).roundToDouble();
    return PriceBreakdown(
      subtotal: subtotal,
      deliveryFee: delivery,
      serviceFee: service,
      total: subtotal + delivery + service,
    );
  }
}

class PriceBreakdown {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;

  const PriceBreakdown({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
  });

  bool get freeDelivery => deliveryFee == 0 && subtotal > 0;
  bool get meetsMinimum => subtotal >= Pricing.minimumOrder;
  double get amountToFreeDelivery =>
      (Pricing.freeDeliveryOver - subtotal).clamp(0, Pricing.freeDeliveryOver).toDouble();
  double get amountToMinimum => (Pricing.minimumOrder - subtotal).clamp(0, Pricing.minimumOrder).toDouble();
}
