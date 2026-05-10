/// Mock implementation of [IrrigationService] that simulates a real
/// ESP32 sensor node with realistic noise, auto-irrigation logic, and tank drainage.
library;

import 'dart:async';
import 'dart:math';

import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';
import 'irrigation_service.dart';

class MockIrrigationService implements IrrigationService {
  // ─── Internal simulated hardware state ─────────────────────────────────

  final _rng = Random();

  double _moisture = 48.0;
  double _tankLevel = 85.0;
  double _temperature = 24.5;
  bool _pumpRunning = false;
  IrrigationMode _mode = IrrigationMode.automatic;
  bool _manualRequest = false;
  int _pumpSpeed = 200; // PWM duty [0–255], matches ESP32 default

  static const double _autoOnThreshold = 30.0;
  static const double _autoOffThreshold = 65.0;

  StreamController<SensorReading>? _controller;
  Timer? _ticker;

  // ─── IrrigationService ──────────────────────────────────────────────────

  @override
  Stream<SensorReading> sensorStream() {
    _controller?.close();
    _controller = StreamController<SensorReading>.broadcast(
      onCancel: () => _ticker?.cancel(),
    );

    _controller!.add(_snapshot());

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
      pumpSpeed: _pumpSpeed,
      lastChanged: DateTime.now(),
    );
  }

  @override
  Future<void> setPumpRunning(bool running) async {
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
      _manualRequest = false;
      _pumpRunning = false;
    } else {
      _pumpRunning = _manualRequest;
    }
  }

  @override
  Future<void> setSpeed(int speed) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _pumpSpeed = speed.clamp(0, 255);
  }

  @override
  Future<List<SensorReading>> getHistory({int hours = 24}) async {
    final readings = <SensorReading>[];
    final now = DateTime.now();

    double sim = 50.0;
    double tank = 90.0;
    bool pump = false;
    final rng = Random(42);

    const intervalMinutes = 30;
    final totalPoints = (hours * 60) ~/ intervalMinutes;

    for (int i = totalPoints; i >= 0; i--) {
      if (pump) {
        sim += 1.8 + rng.nextDouble() * 0.4;
        tank -= 0.35;
        tank = tank.clamp(0.0, 100.0);
      } else {
        sim -= 1.2 + rng.nextDouble() * 0.8;
      }
      sim += (rng.nextDouble() - 0.5) * 2.0;
      sim = sim.clamp(0.0, 100.0);

      if (sim < _autoOnThreshold && tank > 5.0) pump = true;
      if (sim >= _autoOffThreshold || tank <= 5.0) pump = false;

      readings.add(SensorReading(
        moisturePercent: sim,
        temperatureCelsius: 20.0 + rng.nextDouble() * 10.0,
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

  void _stepSimulation() {
    if (_pumpRunning) {
      // Speed scales moisture gain and tank drain (200/255 ≈ 0.78 baseline)
      final factor = _pumpSpeed / 255.0;
      _moisture += factor * 2.8 + _rng.nextDouble() * 0.3;
      _tankLevel -= factor * 0.35;
      _tankLevel = _tankLevel.clamp(0.0, 100.0);
    } else {
      _moisture -= 0.7 + _rng.nextDouble() * 0.5;
    }

    _moisture += (_rng.nextDouble() - 0.5) * 1.8;
    _moisture = _moisture.clamp(0.0, 100.0);

    _temperature += (_rng.nextDouble() - 0.5) * 0.3;
    _temperature = _temperature.clamp(15.0, 45.0);

    if (_tankLevel < 95.0 && _rng.nextDouble() < 0.02) {
      _tankLevel = (_tankLevel + 5.0).clamp(0.0, 100.0);
    }

    if (_mode == IrrigationMode.automatic) {
      if (_moisture < _autoOnThreshold && _tankLevel > 5.0) {
        _pumpRunning = true;
      } else if (_moisture >= _autoOffThreshold || _tankLevel <= 5.0) {
        _pumpRunning = false;
      }
    }
  }

  SensorReading _snapshot() {
    return SensorReading(
      moisturePercent: _moisture,
      temperatureCelsius: _temperature,
      tankLevelPercent: _tankLevel,
      isPumpRunning: _pumpRunning,
      timestamp: DateTime.now(),
    );
  }
}
