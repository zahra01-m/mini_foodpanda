/// How an order's payment currently stands. `succeeded` orders are the
/// only kind created from a card payment — a `failed` charge never
/// reaches [MockDataService.placeOrder]. `pending` covers cash on
/// delivery, collected in person when the order arrives. `refunded` is set
/// by an admin (order detail / dispute handling).
enum PaymentStatus { pending, succeeded, failed, refunded }

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pay on delivery';
      case PaymentStatus.succeeded:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

enum PaymentMethod { card, cashOnDelivery }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on delivery';
    }
  }
}

/// Outcome of a mock card charge from [PaymentService].
class PaymentResult {
  final bool success;
  final String? errorMessage;
  final String? last4;

  const PaymentResult.success({this.last4}) : success = true, errorMessage = null;
  const PaymentResult.failure(String message)
      : success = false,
        errorMessage = message,
        last4 = null;
}

/// Stripe test-mode card numbers this mock recognizes, mirroring the
/// real ones so the UI can hint at them. Swap [PaymentService] for a
/// real Stripe PaymentSheet later without changing any caller.
class TestCards {
  TestCards._();
  static const succeeds = '4242424242424242';
  static const declines = '4000000000000002';
}
