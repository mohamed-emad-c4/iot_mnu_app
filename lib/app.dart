import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'presentation/navigation/main_scaffold.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/setup/ip_setup_screen.dart';

class IrrigationApp extends ConsumerWidget {
  const IrrigationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final ip = ref.watch(espIpProvider);

    return MaterialApp(
      title: 'Smart Irrigation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Show IP setup on first launch (ip == null); go to dashboard otherwise.
      home: ip == null ? const IpSetupScreen() : const MainScaffold(),
    );
  }
}
