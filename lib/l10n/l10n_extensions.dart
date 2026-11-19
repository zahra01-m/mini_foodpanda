import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Shorthand so call sites read `context.l10n.emailLabel` instead of the
/// more verbose `AppLocalizations.of(context)!.emailLabel`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
