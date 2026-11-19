import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/payment_model.dart';

void main() {
  group('PaymentResult', () {
    test('success carries last4 and no error', () {
      const result = PaymentResult.success(last4: '4242');
      expect(result.success, true);
      expect(result.last4, '4242');
      expect(result.errorMessage, null);
    });

    test('failure carries a message and no last4', () {
      const result = PaymentResult.failure('Declined');
      expect(result.success, false);
      expect(result.errorMessage, 'Declined');
      expect(result.last4, null);
    });
  });

  group('PaymentStatus.label', () {
    test('every status has a distinct label', () {
      final labels = PaymentStatus.values.map((s) => s.label).toSet();
      expect(labels.length, PaymentStatus.values.length);
    });
  });

  group('PaymentMethod.label', () {
    test('every method has a distinct label', () {
      final labels = PaymentMethod.values.map((m) => m.label).toSet();
      expect(labels.length, PaymentMethod.values.length);
    });

    test('specific labels read naturally', () {
      expect(PaymentMethod.card.label, 'Card');
      expect(PaymentMethod.cashOnDelivery.label, 'Cash on delivery');
    });
  });

  group('TestCards', () {
    test('succeeds and declines are distinct 16-digit numbers', () {
      expect(TestCards.succeeds.length, 16);
      expect(TestCards.declines.length, 16);
      expect(TestCards.succeeds, isNot(TestCards.declines));
    });
  });
}
