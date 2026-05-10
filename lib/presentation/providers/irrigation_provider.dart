/// All Riverpod providers for the irrigation app.
///
/// The provider graph:
///
///   irrigationServiceProvider  ──►  sensorStreamProvider
///                              ──►  pumpControlProvider
///                              ──►  historyProvider
///
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/irrigation_service.dart';
import '../../data/services/websocket_irrigation_service.dart';
import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';
import 'settings_provider.dart';

// ─── 1. Service provider ──────────────────────────────────────────────────────

final irrigationServiceProvider = Provider<IrrigationService>((ref) {
  final ip = ref.watch(espIpProvider);
  // ip is guaranteed non-null here — app.dart only shows MainScaffold when ip != null
  final service = WebSocketIrrigationService(ipAddress: ip!);
  service.onStatusChange = (status) {
    Future.microtask(
      () => ref.read(wsStatusProvider.notifier).state = status,
    );
  };
  ref.onDispose(service.dispose);
  return service;
});

// ─── 2. Live sensor stream ────────────────────────────────────────────────────

final sensorStreamProvider = StreamProvider<SensorReading>((ref) {
  return ref.watch(irrigationServiceProvider).sensorStream();
});

// ─── 3. Pump control notifier ─────────────────────────────────────────────────

class PumpControlNotifier extends AsyncNotifier<PumpControl> {
  @override
  Future<PumpControl> build() =>
      ref.read(irrigationServiceProvider).getPumpControl();

  Future<void> togglePump() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = !current.manualRunRequest;
    state = AsyncData(
      current.copyWith(manualRunRequest: next, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setPumpRunning(next);
  }

  Future<void> setMode(IrrigationMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(mode: mode, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setIrrigationMode(mode);
  }

  Future<void> setSpeed(int speed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(pumpSpeed: speed, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setSpeed(speed);
  }
}

final pumpControlProvider =
    AsyncNotifierProvider<PumpControlNotifier, PumpControl>(
  PumpControlNotifier.new,
);

// ─── 4. History provider ──────────────────────────────────────────────────────

final historyProvider = FutureProvider<List<SensorReading>>((ref) {
  return ref.watch(irrigationServiceProvider).getHistory(hours: 24);
});

// ─── 5. Derived alert providers ───────────────────────────────────────────────

final isDryAlertActiveProvider = Provider<bool>((ref) {
  final reading = ref.watch(sensorStreamProvider).valueOrNull;
  return reading != null && reading.moisturePercent < 30.0;
});

final isTankLowProvider = Provider<bool>((ref) {
  final reading = ref.watch(sensorStreamProvider).valueOrNull;
  return reading != null && reading.tankLevelPercent < 10.0;
});
