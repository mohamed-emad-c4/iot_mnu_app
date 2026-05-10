import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/esp_ip_repository.dart';

/// Persists the user's preferred [ThemeMode] across restarts.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Soil moisture percentage below which a dry alert fires (default: 30 %).
final moistureThresholdProvider = StateProvider<double>((ref) => 30.0);

/// Singleton repository for reading/writing the ESP32 IP address.
final espIpRepositoryProvider =
    Provider<EspIpRepository>((_) => EspIpRepository());

/// Currently active ESP32 IP address.
/// - null  → not configured (shows IP setup screen)
/// - '__mock__' → user chose to use simulated data
/// - any other string → real ESP32 IP (e.g. "192.168.1.42")
final espIpProvider = StateProvider<String?>((ref) => null);

/// WebSocket connection status used by the Settings screen badge.
enum WsStatus { disconnected, connecting, connected, error }

final wsStatusProvider =
    StateProvider<WsStatus>((ref) => WsStatus.disconnected);
