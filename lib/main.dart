import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Real hardware integration checklist ─────────────────────────────────
  // When you're ready to connect to real IoT hardware, do the following here:
  //
  // 1. HTTP/REST (ESP8266 or ESP32 web server):
  //    No initialisation needed. Just swap MockIrrigationService with
  //    HttpIrrigationService(baseUrl: 'http://192.168.1.XX') in
  //    lib/presentation/providers/irrigation_provider.dart.
  //
  // 2. MQTT:
  //    Initialize your MQTT client here before runApp.
  //    Pass the connected client into MqttIrrigationService.
  //
  // 3. Firebase Realtime Database:
  //    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //    Then swap MockIrrigationService with FirebaseIrrigationService() in the provider.
  // ─────────────────────────────────────────────────────────────────────────

  runApp(
    // ProviderScope is the Riverpod root — required for all providers to work.
    const ProviderScope(
      child: IrrigationApp(),
    ),
  );
}

