import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/payment_model.dart';
import 'package:mini_foodpanda/services/payment_service.dart';

void main() {
  final service = PaymentService();

  group('PaymentService.chargeCard', () {
    test('the Stripe test "succeeds" card returns success with last4', () async {
      final result = await service.chargeCard(
        cardNumber: TestCards.succeeds,
        expiry: '12/30',
        cvv: '123',
        amount: 1000,
      );
      expect(result.success, true);
      expect(result.last4, '4242');
    });

    test('the Stripe test "declines" card always fails', () async {
      final result = await service.chargeCard(
        cardNumber: TestCards.declines,
        expiry: '12/30',
        cvv: '123',
        amount: 1000,
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('declined'));
    });

    test('any other well-formed 16-digit card succeeds', () async {
      final result = await service.chargeCard(
        cardNumber: '4111 1111 1111 1111',
        expiry: '01/29',
        cvv: '999',
        amount: 500,
      );
      expect(result.success, true);
      expect(result.last4, '1111');
    });

    test('rejects a card number that is not 16 digits', () async {
      final result = await service.chargeCard(
        cardNumber: '4242',
        expiry: '12/30',
        cvv: '123',
        amount: 500,
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('valid 16-digit'));
    });

    test('rejects a non-numeric card number', () async {
      final result = await service.chargeCard(
        cardNumber: 'abcd efgh ijkl mnop',
        expiry: '12/30',
        cvv: '123',
        amount: 500,
      );
      expect(result.success, false);
    });

    test('rejects a malformed expiry or short CVV', () async {
      final result = await service.chargeCard(
        cardNumber: TestCards.succeeds,
        expiry: '1230',
        cvv: '12',
        amount: 500,
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('expiry'));
    });
  });
}
