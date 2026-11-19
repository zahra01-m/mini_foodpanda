import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/pricing.dart';
import 'package:mini_foodpanda/core/utils/promo.dart';

void main() {
  test('lookup is case-insensitive and ignores whitespace', () {
    expect(PromoCodes.lookup(' welcome10 ')?.code, 'WELCOME10');
    expect(PromoCodes.lookup('nope'), isNull);
    expect(PromoCodes.lookup(''), isNull);
    expect(PromoCodes.lookup(null), isNull);
  });

  test('WELCOME10 takes 10% off the food, capped at Rs. 300', () {
    expect(PromoCodes.discountFor('WELCOME10', Pricing.of(1000)), 100);
    expect(PromoCodes.discountFor('WELCOME10', Pricing.of(5000)), 300);
  });

  test('a code is ignored below its minimum order', () {
    final price = Pricing.of(400);
    expect(PromoCodes.discountFor('WELCOME10', price), 0);
    expect(PromoCodes.lookup('WELCOME10')!.ineligibleReason(price), contains('Rs. 100'));
  });

  test('FREESHIP waives the delivery fee only when there is one', () {
    expect(PromoCodes.discountFor('FREESHIP', Pricing.of(600)), Pricing.deliveryFee);
    final free = Pricing.of(Pricing.freeDeliveryOver);
    expect(PromoCodes.discountFor('FREESHIP', free), 0);
    expect(PromoCodes.lookup('FREESHIP')!.ineligibleReason(free), isNotNull);
  });

  test('the discount never exceeds the total', () {
    for (final c in PromoCodes.all) {
      final price = Pricing.of(900);
      expect(c.discountFor(price), lessThanOrEqualTo(price.total));
    }
  });
}
