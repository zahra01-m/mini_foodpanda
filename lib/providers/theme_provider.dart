import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to following the device's system setting. The manual
/// Light/Dark/System toggle in the profile screen overrides this for the
/// current app session only — it isn't persisted across restarts (no
/// local-storage dependency added for that yet).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
