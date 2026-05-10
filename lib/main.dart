import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the saved ESP32 IP before building the widget tree so that
  // espIpProvider is synchronously seeded — no FutureProvider cascade needed.
  final prefs = await SharedPreferences.getInstance();
  final savedIp = prefs.getString('esp32_ip');

  runApp(
    ProviderScope(
      overrides: [
        espIpProvider.overrideWith((ref) => savedIp),
      ],
      child: const IrrigationApp(),
    ),
  );
}
