import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';

/// Text field with optional validation, password show/hide toggle and
/// keyboard actions. Works inside or outside a [Form]; all new
/// parameters are optional so existing call sites keep working.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.icon,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _hidden,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        validator: widget.validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        cursorColor: p.red,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: p.inkSoft,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}
