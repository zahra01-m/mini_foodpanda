import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_palette.dart';

/// Short "Order placed!" celebration shown between checkout and the
/// tracking screen: an animated check mark that pops in, then closes itself.
Future<void> showOrderPlacedDialog(BuildContext context) {
  HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OrderPlacedDialog(),
  );
}

class _OrderPlacedDialog extends StatefulWidget {
  const _OrderPlacedDialog();

  @override
  State<_OrderPlacedDialog> createState() => _OrderPlacedDialogState();
}

class _OrderPlacedDialogState extends State<_OrderPlacedDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: p.success,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: p.success.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 22),
              Text('Order placed!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'The restaurant is getting started on your food.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
