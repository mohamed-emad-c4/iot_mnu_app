import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the user's preferred [ThemeMode] across restarts.
///
/// For now it lives in memory; wire it to [SharedPreferences] when needed:
///   prefs.setString('themeMode', mode.name);
///   ThemeMode.values.byName(prefs.getString('themeMode') ?? 'system');
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Soil moisture percentage below which a dry alert fires (default: 30 %).
/// Exposed here so the Settings screen can let the user customise it.
final moistureThresholdProvider = StateProvider<double>((ref) => 30.0);
