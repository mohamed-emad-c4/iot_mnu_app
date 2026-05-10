/// Abstract contract for the irrigation data source.
///
/// All IoT communication is isolated behind this interface.
/// Swap the mock implementation for a real one without touching
/// any UI or provider code.
///
/// Concrete implementations to build later:
///   - [HttpIrrigationService]    → REST API on ESP8266/ESP32 (http package)
///   - [MqttIrrigationService]    → MQTT broker  (mqtt_client package)
///   - [FirebaseIrrigationService]→ Firebase Realtime DB (firebase_database)
library;

import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';

abstract class IrrigationService {
  // ─── Real-time sensor data ───────────────────────────────────────────────

  /// Emits a new [SensorReading] whenever hardware publishes fresh data.
  ///
  /// Replacement guides:
  ///   HTTP  → Poll GET /api/sensor on a [Timer] and add to a [StreamController].
  ///   MQTT  → Subscribe to topic `irrigation/sensor` and map JSON payloads.
  ///   Firebase → `FirebaseDatabase.instance.ref('sensor').onValue.map(...)`.
  Stream<SensorReading> sensorStream();

  // ─── Pump control ────────────────────────────────────────────────────────

  /// Returns the current [PumpControl] state stored on the device / cloud.
  ///
  /// HTTP  → GET /api/pump
  /// MQTT  → Read retained message on `irrigation/pump/state`
  /// Firebase → `ref('pump').get()`
  Future<PumpControl> getPumpControl();

  /// Turns the pump on or off (manual override).
  ///
  /// HTTP  → POST /api/pump/run  body: { "running": true }
  /// MQTT  → Publish `{"cmd":"SET_PUMP","value":1}` to `irrigation/cmd`
  /// Firebase → `ref('pump/manualRun').set(true)`
  Future<void> setPumpRunning(bool running);

  /// Switches between [IrrigationMode.automatic] and [IrrigationMode.manual].
  ///
  /// HTTP  → POST /api/pump/mode  body: { "mode": "auto" }
  /// MQTT  → Publish `{"cmd":"SET_MODE","value":"auto"}` to `irrigation/cmd`
  /// Firebase → `ref('pump/mode').set('auto')`
  Future<void> setIrrigationMode(IrrigationMode mode);

  /// Sets the pump PWM speed [0 – 255].
  ///
  /// WebSocket → send `{"command":"set_speed","value":<speed>}` to ESP32
  /// HTTP  → POST /api/pump/speed  body: { "speed": 200 }
  /// MQTT  → Publish `{"cmd":"SET_SPEED","value":200}` to `irrigation/cmd`
  Future<void> setSpeed(int speed);

  // ─── Historical data ─────────────────────────────────────────────────────

  /// Fetches up to [hours] hours of past sensor readings (newest last).
  ///
  /// HTTP  → GET /api/history?hours=24
  /// MQTT  → Not native; query a time-series DB (InfluxDB) via REST.
  /// Firebase → Query with `orderByChild('timestamp').limitToLast(N)`
  Future<List<SensorReading>> getHistory({int hours = 24});

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  /// Release sockets, MQTT clients, stream controllers, timers.
  void dispose();
}
