import '../models/payment_model.dart';

/// Stands in for a real Stripe PaymentSheet charge. Swapping this out
/// for the real Stripe SDK later means changing this file only — every
/// caller already works against [PaymentResult].
///
/// Test-mode behavior, matching Stripe's own test cards so the habit
/// transfers: [TestCards.succeeds] always clears, [TestCards.declines]
/// always fails, and any other well-formed 16-digit number is treated
/// as a fresh test card and succeeds.
class PaymentService {
  Future<PaymentResult> chargeCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final digits = cardNumber.replaceAll(' ', '');
    if (digits.length != 16 || int.tryParse(digits) == null) {
      return const PaymentResult.failure('Enter a valid 16-digit card number.');
    }
    if (expiry.length != 5 || cvv.length < 3) {
      return const PaymentResult.failure('Check the expiry date and CVV.');
    }

    if (digits == TestCards.declines) {
      return const PaymentResult.failure('Your card was declined.');
    }

    return PaymentResult.success(last4: digits.substring(digits.length - 4));
  }
}
