import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

/// Inline error message used by forms (login, signup, checkout, payment).
/// One consistent look in light and dark mode, and announced to screen
/// readers when it appears (`liveRegion`) — previously each screen
/// hand-rolled its own box and some used fixed `Colors.red`.
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.redTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: p.danger, height: 1.3))),
          ],
        ),
      ),
    );
  }
}
