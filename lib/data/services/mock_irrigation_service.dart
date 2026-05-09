/// Mock implementation of [IrrigationService] that simulates a real
/// Arduino / ESP8266 / ESP32 sensor node with realistic noise, auto-irrigation
/// logic, and tank drainage.
///
/// ─── How to replace this with a real backend ─────────────────────────────────
/// 1. Create a new class implementing [IrrigationService]:
///      class HttpIrrigationService implements IrrigationService { ... }
///      class MqttIrrigationService implements IrrigationService { ... }
///      class FirebaseIrrigationService implements IrrigationService { ... }
///
/// 2. In lib/presentation/providers/irrigation_provider.dart, change the
///    [irrigationServiceProvider] body:
///      final service = HttpIrrigationService(baseUrl: 'http://192.168.1.42');
///
/// That's it — no other file needs to change.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'dart:math';

import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';
import 'irrigation_service.dart';

class MockIrrigationService implements IrrigationService {
  // ─── Internal simulated hardware state ─────────────────────────────────

  final _rng = Random();

  double _moisture = 48.0; // current soil moisture [0–100]
  double _tankLevel = 85.0; // water tank fill level [0–100]
  double _temperature = 24.5; // ambient temperature °C
  bool _pumpRunning = false; // actual pump relay state
  IrrigationMode _mode = IrrigationMode.automatic;
  bool _manualRequest = false; // user's last manual request
  double _flowRate = 0.6; // flow rate [0.0–1.0]

  // Moisture alert threshold (mirrors the provider default of 30 %)
  static const double _autoOnThreshold = 30.0;
  static const double _autoOffThreshold = 65.0;

  StreamController<SensorReading>? _controller;
  Timer? _ticker;

  // ─── IrrigationService ──────────────────────────────────────────────────

  @override
  Stream<SensorReading> sensorStream() {
    _controller?.close();
    _controller = StreamController<SensorReading>.broadcast(
      onCancel: () {
        _ticker?.cancel();
      },
    );

    // Emit an immediate reading so the UI doesn't show a loading state.
    _controller!.add(_snapshot());

    // Simulate hardware polling at ~3-second intervals (ESP typically 1–5 s).
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 3), (_) {
      _stepSimulation();
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(_snapshot());
      }
    });

    return _controller!.stream;
  }

  @override
  Future<PumpControl> getPumpControl() async {
    return PumpControl(
      mode: _mode,
      manualRunRequest: _manualRequest,
      flowRate: _flowRate,
      lastChanged: DateTime.now(),
    );
  }

  @override
  Future<void> setPumpRunning(bool running) async {
    // Simulate ~250 ms network / relay latency
    await Future.delayed(const Duration(milliseconds: 250));
    _manualRequest = running;
    if (_mode == IrrigationMode.manual) {
      _pumpRunning = running;
    }
  }

  @override
  Future<void> setIrrigationMode(IrrigationMode mode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mode = mode;
    if (mode == IrrigationMode.automatic) {
      // Hand pump control back to the auto logic; clear manual request.
      _manualRequest = false;
      _pumpRunning = false;
    } else {
      // Manual: honour the last manual request immediately.
      _pumpRunning = _manualRequest;
    }
  }

  @override
  Future<void> setFlowRate(double rate) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _flowRate = rate.clamp(0.0, 1.0);
  }

  @override
  Future<List<SensorReading>> getHistory({int hours = 24}) async {
    // Generate plausible 24-hour history (one reading every 30 min).
    final readings = <SensorReading>[];
    final now = DateTime.now();

    double sim = 50.0;
    double tank = 90.0;
    bool pump = false;
    final rng = Random(42); // fixed seed for reproducible history

    final intervalMinutes = 30;
    final totalPoints = (hours * 60) ~/ intervalMinutes;

    for (int i = totalPoints; i >= 0; i--) {
      // Apply pump / evaporation physics
      if (pump) {
        sim += 0.6 * 3.0 + rng.nextDouble() * 0.4;
        tank -= 0.6 * 0.4;
        tank = tank.clamp(0.0, 100.0);
      } else {
        sim -= 1.2 + rng.nextDouble() * 0.8;
      }
      sim += (rng.nextDouble() - 0.5) * 2.0; // sensor noise
      sim = sim.clamp(0.0, 100.0);

      // Auto irrigation logic
      if (sim < _autoOnThreshold && tank > 5.0) pump = true;
      if (sim >= _autoOffThreshold || tank <= 5.0) pump = false;

      readings.add(SensorReading(
        moisturePercent: sim,
        temperatureCelsius: 20.0 + rng.nextDouble() * 10.0,
        flowRateLitersPerMin: pump ? _flowRate * 4.8 : 0.0,
        tankLevelPercent: tank,
        isPumpRunning: pump,
        timestamp: now.subtract(Duration(minutes: i * intervalMinutes)),
      ));
    }

    return readings;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller?.close();
  }

  // ─── Private simulation helpers ─────────────────────────────────────────

  /// Advances the simulated hardware state by one tick (~3 s real time).
  void _stepSimulation() {
    if (_pumpRunning) {
      // Pump is on: add water, drain tank
      final added = _flowRate * 2.8 + _rng.nextDouble() * 0.3;
      _moisture += added;
      _tankLevel -= _flowRate * 0.35;
      _tankLevel = _tankLevel.clamp(0.0, 100.0);
    } else {
      // Natural evaporation + plant uptake
      _moisture -= 0.7 + _rng.nextDouble() * 0.5;
    }

    // Realistic ADC noise from the capacitive moisture sensor
    _moisture += (_rng.nextDouble() - 0.5) * 1.8;
    _moisture = _moisture.clamp(0.0, 100.0);

    // Temperature drifts slowly
    _temperature += (_rng.nextDouble() - 0.5) * 0.3;
    _temperature = _temperature.clamp(15.0, 45.0);

    // Slowly refill tank (rain / manual refill simulation, very slow)
    if (_tankLevel < 95.0 && _rng.nextDouble() < 0.02) {
      _tankLevel = (_tankLevel + 5.0).clamp(0.0, 100.0);
    }

    // ─── Auto irrigation logic (mirrors what the ESP firmware does) ──────
    if (_mode == IrrigationMode.automatic) {
      if (_moisture < _autoOnThreshold && _tankLevel > 5.0) {
        _pumpRunning = true;
      } else if (_moisture >= _autoOffThreshold || _tankLevel <= 5.0) {
        _pumpRunning = false;
      }
    }
    // In manual mode the pump state is already set by [setPumpRunning].
  }

  SensorReading _snapshot() {
    return SensorReading(
      moisturePercent: _moisture,
      temperatureCelsius: _temperature,
      flowRateLitersPerMin: _pumpRunning ? _flowRate * 4.8 : 0.0,
      tankLevelPercent: _tankLevel,
      isPumpRunning: _pumpRunning,
      timestamp: DateTime.now(),
    );
  }
}
