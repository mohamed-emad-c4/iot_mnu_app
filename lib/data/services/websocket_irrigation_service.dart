import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/entities/pump_control.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../presentation/providers/settings_provider.dart';
import 'irrigation_service.dart';

class WebSocketIrrigationService implements IrrigationService {
  final String ipAddress;
  static const int _port = 81;
  static const int _maxHistory = 288; // 24 h at 5-min intervals

  WebSocketIrrigationService({required this.ipAddress});

  WebSocketChannel? _channel;
  StreamController<SensorReading>? _sensorController;
  StreamSubscription? _wsSub;

  PumpControl _latestPump = PumpControl.initial();
  final List<SensorReading> _history = [];

  bool _disposed = false;
  int _retrySeconds = 2;
  Timer? _reconnectTimer;

  void Function(WsStatus)? onStatusChange;

  // ─── Connection ──────────────────────────────────────────────────────────

  void _connect() {
    if (_disposed) return;
    onStatusChange?.call(WsStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ipAddress:$_port'));
      _wsSub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      onStatusChange?.call(WsStatus.connected);
      _retrySeconds = 2;
    } catch (_) {
      onStatusChange?.call(WsStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final reading = _parseReading(map);
      _latestPump = _parsePump(map);

      if (!(_sensorController?.isClosed ?? true)) {
        _sensorController!.add(reading);
      }

      _history.add(reading);
      if (_history.length > _maxHistory) _history.removeAt(0);
    } catch (_) {
      // Malformed JSON — skip silently
    }
  }

  void _onError(Object _) {
    onStatusChange?.call(WsStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    onStatusChange?.call(WsStatus.disconnected);
    if (!_disposed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _wsSub?.cancel();
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _retrySeconds), () {
      if (!_disposed) {
        _retrySeconds = (_retrySeconds * 2).clamp(2, 60);
        _connect();
      }
    });
  }

  // ─── Parsing ─────────────────────────────────────────────────────────────

  // ESP32 sends: {"moisture": int, "pump": bool, "auto_mode": bool}
  SensorReading _parseReading(Map<String, dynamic> map) {
    final moisture = (map['moisture'] as num?)?.toDouble() ?? 0.0;
    final pumpOn = map['pump'] as bool? ?? false;
    return SensorReading(
      moisturePercent: moisture.clamp(0.0, 100.0),
      temperatureCelsius: null,
      flowRateLitersPerMin: 0.0,
      tankLevelPercent: 0.0,
      isPumpRunning: pumpOn,
      timestamp: DateTime.now(),
    );
  }

  PumpControl _parsePump(Map<String, dynamic> map) {
    final pumpOn = map['pump'] as bool? ?? false;
    final autoMode = map['auto_mode'] as bool? ?? true;
    return PumpControl(
      mode: autoMode ? IrrigationMode.automatic : IrrigationMode.manual,
      manualRunRequest: pumpOn,
      flowRate: _latestPump.flowRate,
      lastChanged: DateTime.now(),
    );
  }

  // ─── Commands ────────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> command) {
    try {
      _channel?.sink.add(jsonEncode(command));
    } catch (_) {
      // Channel not ready
    }
  }

  // ─── IrrigationService ───────────────────────────────────────────────────

  @override
  Stream<SensorReading> sensorStream() {
    _sensorController?.close();
    _sensorController = StreamController<SensorReading>.broadcast();
    if (_channel == null) _connect();
    return _sensorController!.stream;
  }

  @override
  Future<PumpControl> getPumpControl() async => _latestPump;

  @override
  Future<void> setPumpRunning(bool running) async {
    _send({'command': running ? 'pump_on' : 'pump_off'});
    _latestPump = _latestPump.copyWith(
      manualRunRequest: running,
      lastChanged: DateTime.now(),
    );
  }

  @override
  Future<void> setIrrigationMode(IrrigationMode mode) async {
    if (mode == IrrigationMode.automatic) {
      _send({'command': 'auto'});
    }
    _latestPump = _latestPump.copyWith(
      mode: mode,
      lastChanged: DateTime.now(),
    );
  }

  @override
  Future<void> setFlowRate(double rate) async {
    // ESP32 protocol has no flow-rate command; stored app-side only.
    _latestPump = _latestPump.copyWith(
      flowRate: rate.clamp(0.0, 1.0),
      lastChanged: DateTime.now(),
    );
  }

  @override
  Future<List<SensorReading>> getHistory({int hours = 24}) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _history.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _wsSub?.cancel();
    _channel?.sink.close();
    _sensorController?.close();
  }
}
