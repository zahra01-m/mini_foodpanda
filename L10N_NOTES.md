# Urdu localization

## Setup (one-time, automatic)
Nothing to configure — `pubspec.yaml` has `generate: true` and `l10n.yaml`
points at `lib/l10n/`, so `flutter pub get` (or `flutter run`/`flutter build`)
automatically generates `lib/l10n/app_localizations.dart` from the two ARB
files. Just run:
```
flutter pub get
```

## What's covered right now
The full pipeline is wired in and working end to end for one complete,
demoable slice: **role selector → login → signup → profile**, including
the app's dark/light-mode toggle screen. Switch languages either via the
device's system language, or the Language toggle (Auto/EN/اردو) on the
Profile screen.

Urdu is RTL — because this uses Flutter's real `flutter_localizations`
delegates rather than a hand-rolled string swap, the whole page mirrors
to right-to-left automatically for the `ur` locale (paddings, icons,
text alignment), with no extra work.

The "Mini FoodPanda" brand name is deliberately left in Latin script in
both languages, matching how bilingual apps usually treat brand names
(e.g. the real Foodpanda keeps its English name in Urdu UI too).

## What isn't covered yet
The rest of the app's ~300 remaining UI strings (restaurant list, cart,
checkout, order tracking, admin screens, etc.) are still hardcoded
English. Extending coverage is the same mechanical pattern used here,
just repeated more times:
1. Add a key + English value to `lib/l10n/app_en.arb`.
2. Add the Urdu translation to `lib/l10n/app_ur.arb` (same key).
3. Replace the hardcoded string with `context.l10n.yourKey`
   (add `import '.../l10n/l10n_extensions.dart';` if the file doesn't already).

Order-status / dispute-status labels (`OrderStatus.label` etc. in
`order_model.dart`) are a special case — they're plain Dart getters with
no `BuildContext`, so localizing those means turning them into functions
that take an `AppLocalizations` (or a `BuildContext`) instead, which is a
slightly bigger change than the simple three-step pattern above.
