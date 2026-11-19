// Requires `flutter pub get` (or `flutter gen-l10n`) to have generated
// lib/l10n/app_localizations.dart first — that's automatic on this
// project since pubspec.yaml has `generate: true`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/l10n/app_localizations.dart';
import 'package:mini_foodpanda/screens/auth/role_selector_screen.dart';

Widget _appWithLocale(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const RoleSelectorScreen(),
  );
}

void main() {
  testWidgets('shows English role labels for the en locale', (tester) async {
    await tester.pumpWidget(_appWithLocale(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('shows Urdu role labels for the ur locale', (tester) async {
    await tester.pumpWidget(_appWithLocale(const Locale('ur')));
    await tester.pumpAndSettle();
    expect(find.text('کسٹمر'), findsOneWidget);
    expect(find.text('رائیڈر'), findsOneWidget);
    expect(find.text('ایڈمن'), findsOneWidget);
  });

  testWidgets('the brand name stays in Latin script in both locales', (tester) async {
    await tester.pumpWidget(_appWithLocale(const Locale('ur')));
    await tester.pumpAndSettle();
    expect(find.text('Mini FoodPanda'), findsOneWidget);
  });

  testWidgets('ur locale renders the page right-to-left', (tester) async {
    await tester.pumpWidget(_appWithLocale(const Locale('ur')));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('کسٹمر'));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
