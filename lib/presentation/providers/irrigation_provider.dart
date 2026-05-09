/// All Riverpod providers for the irrigation app.
///
/// The provider graph:
///
///   irrigationServiceProvider  ──►  sensorStreamProvider
///                              ──►  pumpControlProvider
///                              ──►  historyProvider
///
/// To swap the data source, change ONE line in [irrigationServiceProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/irrigation_service.dart';
import '../../data/services/mock_irrigation_service.dart';
import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';

// ─── 1. Service provider ──────────────────────────────────────────────────────
//
// ┌──────────────────────────────────────────────────────────────────────────┐
// │  TO CONNECT REAL HARDWARE:                                               │
// │  Replace `MockIrrigationService()` with your concrete implementation:    │
// │                                                                          │
// │  HTTP/REST  → HttpIrrigationService(baseUrl: 'http://192.168.1.42')     │
// │  MQTT       → MqttIrrigationService(broker: 'mqtt://broker.local')      │
// │  Firebase   → FirebaseIrrigationService()                                │
// └──────────────────────────────────────────────────────────────────────────┘
final irrigationServiceProvider = Provider<IrrigationService>((ref) {
  final service = MockIrrigationService();
  ref.onDispose(service.dispose);
  return service;
});

// ─── 2. Live sensor stream ────────────────────────────────────────────────────

/// Provides a real-time stream of sensor snapshots.
/// Every widget that watches this provider automatically rebuilds when
/// the hardware (or mock) sends a new reading (~every 3 s).
final sensorStreamProvider = StreamProvider<SensorReading>((ref) {
  return ref.watch(irrigationServiceProvider).sensorStream();
});

// ─── 3. Pump control notifier ─────────────────────────────────────────────────

class PumpControlNotifier extends AsyncNotifier<PumpControl> {
  @override
  Future<PumpControl> build() =>
      ref.read(irrigationServiceProvider).getPumpControl();

  /// Toggle pump on/off (manual mode only).
  Future<void> togglePump() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = !current.manualRunRequest;
    // Optimistic update so the UI responds instantly.
    state = AsyncData(
      current.copyWith(manualRunRequest: next, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setPumpRunning(next);
  }

  /// Switch between automatic and manual irrigation modes.
  Future<void> setMode(IrrigationMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(mode: mode, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setIrrigationMode(mode);
  }

  /// Update the flow-rate setpoint [0.0 – 1.0].
  Future<void> setFlowRate(double rate) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(flowRate: rate, lastChanged: DateTime.now()),
    );
    await ref.read(irrigationServiceProvider).setFlowRate(rate);
  }
}

final pumpControlProvider =
    AsyncNotifierProvider<PumpControlNotifier, PumpControl>(
  PumpControlNotifier.new,
);

// ─── 4. History provider ──────────────────────────────────────────────────────

/// Fetches the last 24-hour history of sensor readings.
/// Invalidate this provider to force a refresh: `ref.invalidate(historyProvider)`.
final historyProvider = FutureProvider<List<SensorReading>>((ref) {
  return ref.watch(irrigationServiceProvider).getHistory(hours: 24);
});

// ─── 5. Derived alert providers ───────────────────────────────────────────────

/// True when the latest reading is below the dry threshold (30 %).
final isDryAlertActiveProvider = Provider<bool>((ref) {
  final reading = ref.watch(sensorStreamProvider).valueOrNull;
  return reading != null && reading.moisturePercent < 30.0;
});

/// True when the tank is critically low (< 10 %).
final isTankLowProvider = Provider<bool>((ref) {
  final reading = ref.watch(sensorStreamProvider).valueOrNull;
  return reading != null && reading.tankLevelPercent < 10.0;
});
