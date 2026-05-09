import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'presentation/navigation/main_scaffold.dart';
import 'presentation/providers/settings_provider.dart';

/// Root widget of the Smart Irrigation app.
///
/// Wrapped in [ProviderScope] by [main.dart] so every descendant can access
/// Riverpod providers.
class IrrigationApp extends ConsumerWidget {
  const IrrigationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild only when the user explicitly changes the theme
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Smart Irrigation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScaffold(),
    );
  }
}
