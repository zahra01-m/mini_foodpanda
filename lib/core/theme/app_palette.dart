import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_colors_dark.dart';

/// Brightness-aware colours. Widgets that used `AppColors.inkSoft`,
/// `AppColors.card` etc. directly stayed light-toned in dark mode; use
/// `context.palette.inkSoft` instead and the right shade is picked
/// automatically.
@immutable
class AppPalette {
  final Color bg, card, line, ink, inkSoft, red, redBright, redDeep, redTint;
  final Color beige1, beige2, gold, warning, shadow, success, danger;

  /// Text / icon colour that sits on top of [red] (buttons, badges).
  final Color onRed;

  /// Brand gradient for hero areas (splash, loaders, image fallbacks).
  final List<Color> heroGradient;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.red,
    required this.redBright,
    required this.redDeep,
    required this.redTint,
    required this.beige1,
    required this.beige2,
    required this.gold,
    required this.warning,
    required this.shadow,
    required this.success,
    required this.danger,
    required this.onRed,
    required this.heroGradient,
  });

  static const light = AppPalette(
    bg: AppColors.beige0,
    card: AppColors.card,
    line: AppColors.line,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    red: AppColors.red,
    redBright: AppColors.redBright,
    redDeep: AppColors.redDeep,
    redTint: AppColors.redTint,
    beige1: AppColors.beige1,
    beige2: AppColors.beige2,
    gold: AppColors.gold,
    warning: AppColors.warning,
    shadow: AppColors.shadow,
    success: AppColors.success,
    danger: Color(0xFFB3261E),
    onRed: Colors.white,
    heroGradient: AppColors.heroGradient,
  );

  static const dark = AppPalette(
    bg: AppColorsDark.beige0,
    card: AppColorsDark.card,
    line: AppColorsDark.line,
    ink: AppColorsDark.ink,
    inkSoft: AppColorsDark.inkSoft,
    red: AppColorsDark.red,
    redBright: AppColorsDark.redBright,
    redDeep: AppColorsDark.redDeep,
    redTint: AppColorsDark.redTint,
    beige1: AppColorsDark.beige1,
    beige2: AppColorsDark.beige2,
    gold: AppColorsDark.gold,
    warning: AppColorsDark.warning,
    shadow: AppColorsDark.shadow,
    success: AppColorsDark.success,
    danger: Color(0xFFF2B8B5),
    onRed: Color(0xFF1A0F0A),
    heroGradient: AppColors.heroGradient,
  );
}

extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}
