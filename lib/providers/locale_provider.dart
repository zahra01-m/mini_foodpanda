import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Null means "follow the device's system language" — MaterialApp then
/// picks whichever of [AppLocalizations.supportedLocales] best matches.
/// The Language toggle in the profile screen overrides this for the
/// current app session only (not persisted across restarts, same as
/// [themeModeProvider]).
final localeProvider = StateProvider<Locale?>((ref) => null);
