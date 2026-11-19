import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import 'food_loader.dart';

/// App-wide primary / outlined button.
///
/// * Filled variant: brand gradient with a real ripple, a gentle press
///   scale, and a clearly visible disabled state (the old version turned
///   fully transparent when disabled, so a "disabled" button looked like
///   floating text).
/// * [loading] keeps the button's look but blocks taps and announces the
///   busy state to screen readers.
class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlined = widget.outlined;

    final Color fg = outlined
        ? (_enabled ? (isDark ? p.redDeep : p.red) : p.inkSoft)
        : (_enabled || widget.loading ? p.onRed : p.ink.withValues(alpha: 0.6));

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: widget.loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 22,
              width: 22,
              child: FoodSpinner(size: 22, color: outlined ? p.red : p.onRed),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: fg,
                        ),
                  ),
                ),
              ],
            ),
    );

    if (outlined) {
      // The button's own label comes from its Text child; only the
      // loading state (spinner, no text) needs an explicit announcement.
      return Semantics(
        label: widget.loading ? '${widget.label}, loading' : null,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: _enabled ? widget.onPressed : null, child: content),
        ),
      );
    }

    final radius = BorderRadius.circular(14);
    final showGradient = _enabled || widget.loading;

    // No `excludeSemantics` here: that would also strip the InkWell's tap
    // action, leaving screen-reader users unable to activate the button.
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? '${widget.label}, loading' : null,
      child: AnimatedScale(
        scale: _pressed && _enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: showGradient
                ? [BoxShadow(color: p.red.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 8))]
                : const [],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: showGradient ? null : p.line.withValues(alpha: 0.7),
                gradient: showGradient
                    ? LinearGradient(
                        colors: [p.redBright, p.red],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: _enabled ? widget.onPressed : null,
                onHighlightChanged: (v) {
                  if (_pressed != v) setState(() => _pressed = v);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Center(child: content),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
