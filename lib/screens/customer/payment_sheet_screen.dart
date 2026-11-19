import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/card_input_form.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_banner.dart';

/// Stands in for Stripe's PaymentSheet. Pop this with a [PaymentResult]
/// via [Navigator.pop] — [CheckoutScreen] awaits it and only places the
/// order once `result.success` is true.
class PaymentSheetScreen extends ConsumerStatefulWidget {
  final double amount;
  const PaymentSheetScreen({super.key, required this.amount});

  @override
  ConsumerState<PaymentSheetScreen> createState() => _PaymentSheetScreenState();
}

class _PaymentSheetScreenState extends ConsumerState<PaymentSheetScreen> {
  final _number = TextEditingController(
      text: TestCards.succeeds.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim());
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');

  bool _processing = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    final result = await ref.read(paymentServiceProvider).chargeCard(
          cardNumber: _number.text,
          expiry: _expiry.text,
          cvv: _cvv.text,
          amount: widget.amount,
        );
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, result);
    } else {
      setState(() {
        _processing = false;
        _error = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel payment',
          onPressed: _processing ? null : () => Navigator.pop(context, const PaymentResult.failure('Cancelled')),
        ),
      ),
      // Scrollable form + pinned pay button: the old fixed Column with a
      // Spacer overflowed as soon as the keyboard opened on a small phone.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount due', style: TextStyle(color: p.inkSoft)),
                            Text('Rs. ${widget.amount.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: p.redDeep)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CardInputForm(numberController: _number, expiryController: _expiry, cvvController: _cvv),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: ErrorBanner(message: _error!),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CustomButton(
                label: 'Pay Rs. ${widget.amount.toStringAsFixed(0)}',
                loading: _processing,
                onPressed: _processing ? null : _pay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
