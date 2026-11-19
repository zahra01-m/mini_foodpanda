import 'package:flutter/material.dart';

/// Dark counterpart of [AppColors], same field names so the two palettes
/// stay easy to compare. Used by `AppTheme.dark` for every Material
/// surface that reads from `Theme.of(context)` — Scaffold background,
/// AppBar, Card, buttons, text fields, dividers, and the text theme.
///
/// Scope note: a large part of this app also reaches for `AppColors.X`
/// directly inside widget code (secondary text, borders, icon accents —
/// roughly 150 call sites across ~35 files) rather than going through the
/// theme. Those keep their warm light-mode tone even in dark mode; fully
/// inverting them means routing each one through `Theme.of(context)`
/// instead of the `AppColors` constant, which is a much larger, separate
/// pass across the app rather than a theme change.
class AppColorsDark {
  AppColorsDark._();

  static const Color beige0 = Color(0xFF17120E); // scaffold background
  static const Color beige1 = Color(0xFF1F1812);
  static const Color beige2 = Color(0xFF2A2018);
  static const Color card = Color(0xFF221A14);
  static const Color line = Color(0xFF3A2E22);

  static const Color ink = Color(0xFFF1E6D8);
  static const Color inkSoft = Color(0xFFB8A88F);

  static const Color red = Color(0xFFE2593B);
  static const Color redBright = Color(0xFFF2734F);
  static const Color redDeep = Color(0xFFF08A6A);
  static const Color redTint = Color(0xFF3A241C);

  static const Color gold = Color(0xFFE0B45C);
  static const Color success = Color(0xFF6FBE7E);
  static const Color warning = Color(0xFFE0B24A);

  static const Color shadow = Color(0x40000000);
}
