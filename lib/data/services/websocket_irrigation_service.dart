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
      // In web_socket_channel >=2.4 the TCP handshake is asynchronous.
      // If `ready` is not explicitly handled, a connection failure
      // (SocketException, etc.) becomes an unhandled exception even though
      // the stream's onError is set. Catch it here and route it through the
      // normal error path.
      _channel!.ready
          .then((_) {
            if (!_disposed) {
              onStatusChange?.call(WsStatus.connected);
              _retrySeconds = 2;
            }
          })
          .catchError((Object error) {
            if (!_disposed) _onError(error);
          });
    } catch (_) {
      onStatusChange?.call(WsStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;

      // ACK messages like {"status":"pump_on"} or {"status":"speed_set","value":200}
      if (!_isSensorFrame(map)) {
        _latestPump = _parsePump(map);
        return;
      }

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

  // Sensor frames contain "moisture"; ACK frames contain only "status"
  bool _isSensorFrame(Map<String, dynamic> map) => map.containsKey('moisture');

  // ESP32 sends: {"moisture","raw_soil","pump","auto_mode","water_cm","water_lvl","pump_speed"}
  SensorReading _parseReading(Map<String, dynamic> map) {
    final moisture = (map['moisture'] as num?)?.toDouble() ?? 0.0;
    final pumpOn = map['pump'] as bool? ?? false;
    final waterLvl = (map['water_lvl'] as num?)?.toDouble() ?? 0.0;
    return SensorReading(
      moisturePercent: moisture.clamp(0.0, 100.0),
      temperatureCelsius: null,
      tankLevelPercent: waterLvl.clamp(0.0, 100.0),
      isPumpRunning: pumpOn,
      timestamp: DateTime.now(),
    );
  }

  PumpControl _parsePump(Map<String, dynamic> map) {
    final pumpOn = map['pump'] as bool? ?? _latestPump.manualRunRequest;
    final autoMode = map['auto_mode'] as bool? ?? true;
    // pump_speed is broadcast by ESP32; fall back to last known speed
    final speed =
        (map['pump_speed'] as num?)?.toInt() ??
        (map['value'] as num?)?.toInt() ?? // from speed_set ACK
        _latestPump.pumpSpeed;
    return PumpControl(
      mode: autoMode ? IrrigationMode.automatic : IrrigationMode.manual,
      manualRunRequest: pumpOn,
      pumpSpeed: speed.clamp(0, 255),
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
    _latestPump = _latestPump.copyWith(mode: mode, lastChanged: DateTime.now());
  }

  @override
  Future<void> setSpeed(int speed) async {
    final clamped = speed.clamp(0, 255);
    _send({'command': 'set_speed', 'value': clamped});
    _latestPump = _latestPump.copyWith(
      pumpSpeed: clamped,
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
