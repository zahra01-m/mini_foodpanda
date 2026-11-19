import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_palette.dart';

/// Card number / expiry / CVV fields for the mock PaymentSheet. Purely
/// cosmetic formatting — [PaymentService] does the actual validation.
class CardInputForm extends StatelessWidget {
  final TextEditingController numberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;

  const CardInputForm({
    super.key,
    required this.numberController,
    required this.expiryController,
    required this.cvvController,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: numberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Card number',
            counterText: '',
            hintText: '4242 4242 4242 4242',
            prefixIcon: Icon(Icons.credit_card_rounded, size: 20),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Expiry', counterText: '', hintText: 'MM/YY'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: p.redDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Test mode — use 4242 4242 4242 4242 to succeed, or 4000 0000 0000 0002 to see a decline.',
                  style: TextStyle(color: p.inkSoft, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}
