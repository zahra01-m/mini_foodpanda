import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseInitError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Most likely cause: `flutterfire configure` hasn't been run yet.
    // We still launch the app so the rest of the UI is inspectable,
    // but show a clear setup screen instead of a random crash.
    firebaseInitError = e;
  }

  runApp(ProviderScope(child: MiniFoodPandaApp(firebaseInitError: firebaseInitError)));
}

class MiniFoodPandaApp extends ConsumerWidget {
  final Object? firebaseInitError;
  const MiniFoodPandaApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Mini FoodPanda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      scrollBehavior: const _AppScrollBehavior(),
      // On wide windows (desktop / web) keep the app in a centred column
      // instead of stretching every card and form edge to edge.
      builder: (context, child) {
        // Cap extreme system font scaling so tight rows don't overflow.
        final mq = MediaQuery.of(context);
        final content = MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
          child: child ?? const SizedBox.shrink(),
        );
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth <= _maxContentWidth) return content;
            final p = context.palette;
            return ColoredBox(
              color: p.beige1,
              child: Center(
                child: SizedBox(
                  width: _maxContentWidth,
                  height: c.maxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: p.line))),
                    child: ClipRect(child: content),
                  ),
                ),
              ),
            );
          },
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: firebaseInitError == null
          ? const SplashScreen()
          : _FirebaseSetupNeededScreen(error: firebaseInitError!),
    );
  }
}

const double _maxContentWidth = 760;

/// Flutter ignores mouse dragging by default, which made the horizontal
/// chip rows impossible to scroll with a mouse in Chrome / on desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      };
}

/// Shown instead of crashing when Firebase hasn't been configured yet
/// (i.e. `flutterfire configure` hasn't been run in this project).
class _FirebaseSetupNeededScreen extends StatelessWidget {
  final Object error;
  const _FirebaseSetupNeededScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded, size: 48, color: p.red),
                const SizedBox(height: 18),
                Text('Firebase isn\'t configured yet', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'Run `flutterfire configure` in the project root to generate '
                  'lib/firebase_options.dart from your Firebase project, then restart the app.',
                  style: TextStyle(color: p.inkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text('$error', style: TextStyle(color: p.inkSoft, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
