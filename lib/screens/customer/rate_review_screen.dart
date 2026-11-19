import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../providers/review_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_banner.dart';

class RateReviewScreen extends ConsumerStatefulWidget {
  final FoodOrder order;
  const RateReviewScreen({super.key, required this.order});

  @override
  ConsumerState<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends ConsumerState<RateReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const _ratingLabels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    // A failed submit used to leave the button spinning forever.
    try {
      await ref.read(reviewServiceProvider).submitReview(
            orderId: widget.order.id,
            restaurantId: widget.order.restaurantId,
            customerId: widget.order.customerId,
            rating: _rating,
            comment: _comment.text.trim(),
          );
      ref.invalidate(restaurantReviewsProvider(widget.order.restaurantId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'We couldn\'t send your review. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text('Rate ${widget.order.restaurantName}')),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How was your order?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return Semantics(
                  button: true,
                  selected: i + 1 == _rating,
                  label: '${i + 1} star${i == 0 ? '' : 's'}',
                  child: IconButton(
                    iconSize: 36,
                    icon: AnimatedScale(
                      // The chosen star pops; filled stars are a touch bigger.
                      scale: i + 1 == _rating ? 1.3 : (filled ? 1.0 : 0.88),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.elasticOut,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          key: ValueKey(filled),
                          color: p.gold,
                        ),
                      ),
                    ),
                    onPressed: _submitting
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = i + 1);
                          },
                  ),
                );
              }),
            ),
            Center(
              child: Text(_ratingLabels[_rating - 1],
                  style: TextStyle(color: p.redDeep, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Add a comment (optional)',
                hintText: 'What did you like or what could be better?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            CustomButton(
              label: 'Submit review',
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
