import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

/// Central theme. Display headings use `Sora` (a geometric, slightly quirky
/// sans with real personality) and body text uses `Plus Jakarta Sans`
/// (warm, rounded, very readable) — a more distinctive pairing than the
/// default Material fonts, while keeping the beige/red brand palette.
///
/// Light and dark are produced by the same builder from [AppPalette], so
/// the two can never drift apart, and every Material component the app
/// uses (chips, dialogs, sheets, snack bars, switches, nav bar…) is styled
/// here once instead of falling back to Material defaults.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Accent used for text-like elements: the deeper salmon reads better
    // than the saturated red on dark surfaces.
    final accent = isDark ? p.redDeep : p.red;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.red,
        primary: p.red,
        onPrimary: p.onRed,
        secondary: p.gold,
        surface: p.bg,
        onSurface: p.ink,
        error: p.danger,
        outline: p.line,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: p.bg,
      splashFactory: InkSparkle.splashFactory,
    );

    final displayFont = GoogleFonts.sora();
    final bodyFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final buttonText = bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      textTheme: bodyFont.copyWith(
        headlineLarge: displayFont.copyWith(
            fontSize: 34, fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.5),
        headlineMedium: displayFont.copyWith(
            fontSize: 24, fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.3),
        titleLarge: displayFont.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: p.ink),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: p.ink, height: 1.4),
        bodySmall: bodyFont.bodySmall?.copyWith(color: p.inkSoft),
        labelLarge: bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: displayFont.copyWith(
            fontSize: 20, fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line, width: 1),
        ),
      ),

      // ── Buttons ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.red,
          foregroundColor: p.onRed,
          // A disabled primary button must still look like a button.
          disabledBackgroundColor: p.line.withValues(alpha: 0.7),
          disabledForegroundColor: p.ink.withValues(alpha: 0.6),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: buttonShape,
          elevation: 0,
          textStyle: buttonText,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(p.onRed.withValues(alpha: 0.12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.red,
          foregroundColor: p.onRed,
          disabledBackgroundColor: p.line.withValues(alpha: 0.7),
          disabledForegroundColor: p.ink.withValues(alpha: 0.6),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: buttonShape,
          textStyle: buttonText,
        ).copyWith(
          side: WidgetStateProperty.resolveWith<BorderSide?>(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled) ? p.line : accent,
              width: 1.4,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink),
      ),

      // ── Inputs ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: TextStyle(color: p.inkSoft.withValues(alpha: 0.75)),
        labelStyle: TextStyle(color: p.inkSoft),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) return TextStyle(color: p.danger);
          if (states.contains(WidgetState.focused)) return TextStyle(color: accent);
          return TextStyle(color: p.inkSoft);
        }),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? accent : p.inkSoft,
        ),
        errorStyle: TextStyle(color: p.danger, fontSize: 12.5),
        border: inputBorder(p.line),
        enabledBorder: inputBorder(p.line),
        disabledBorder: inputBorder(p.line.withValues(alpha: 0.5)),
        focusedBorder: inputBorder(p.red, 1.8),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.8),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.red,
        selectionHandleColor: p.red,
        selectionColor: p.red.withValues(alpha: 0.25),
      ),

      // ── Selection controls & chips ───────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.redTint,
        disabledColor: p.beige1,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: p.red, width: 1.4)
              : BorderSide(color: p.line),
        ),
        labelStyle: bodyFont.labelLarge?.copyWith(color: p.ink, fontWeight: FontWeight.w600, fontSize: 13),
        iconTheme: IconThemeData(color: p.redDeep, size: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? Colors.white : p.inkSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? p.red : p.beige1,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : p.line,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? p.red : null,
        ),
        checkColor: WidgetStatePropertyAll(p.onRed),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: p.red, width: 2)
              : BorderSide(color: p.inkSoft, width: 1.6),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected) ? p.redTint : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected) ? p.redDeep : p.inkSoft,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.line)),
          textStyle: WidgetStatePropertyAll(
            bodyFont.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSoft,
        subtitleTextStyle: bodyFont.bodyMedium?.copyWith(color: p.inkSoft, fontSize: 13.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.red),
      dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),

      // ── Overlays & navigation ────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.beige2 : p.ink,
        contentTextStyle: bodyFont.bodyMedium?.copyWith(color: isDark ? p.ink : p.bg, height: 1.35),
        actionTextColor: p.gold,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.line),
        ),
        titleTextStyle: displayFont.copyWith(fontSize: 19, fontWeight: FontWeight.w700, color: p.ink),
        contentTextStyle: bodyFont.bodyMedium?.copyWith(color: p.ink, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.redTint,
        elevation: 8,
        shadowColor: p.shadow,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.redDeep : p.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => bodyFont.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? p.ink : p.inkSoft,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Side-slide transition used for every route push: the new page slides in
/// from the end edge (right in English, left in Urdu) while fading in, and
/// the page underneath drifts the other way a little (parallax) and dims.
class _FadeThroughTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final enter = CurveTween(curve: Curves.easeOutCubic);
    final exit = CurveTween(curve: Curves.easeInOutCubic);

    // Page being covered by a newer route.
    final parallax = Tween<Offset>(begin: Offset.zero, end: Offset(-0.12 * sign, 0))
        .chain(exit)
        .animate(secondaryAnimation);
    final dim = Tween<double>(begin: 1, end: 0.85).chain(exit).animate(secondaryAnimation);

    // This page arriving.
    final slideIn = Tween<Offset>(begin: Offset(0.22 * sign, 0), end: Offset.zero)
        .chain(enter)
        .animate(animation);
    final fadeIn = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: const Interval(0, 0.7, curve: Curves.easeOut)))
        .animate(animation);

    return SlideTransition(
      position: parallax,
      child: FadeTransition(
        opacity: dim,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(opacity: fadeIn, child: child),
        ),
      ),
    );
  }
}
