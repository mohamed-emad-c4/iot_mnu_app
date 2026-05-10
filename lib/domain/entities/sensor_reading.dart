/// Domain entity representing a single snapshot from the irrigation sensor node.
///
/// This entity is hardware-agnostic. Whether the data arrives over WebSocket,
/// HTTP, MQTT, or Firebase, it is always normalised into this shape before
/// reaching the presentation layer.
library;

/// Classification of the current soil moisture.
enum MoistureStatus {
  /// Moisture < 30 % — irrigation recommended.
  dry,

  /// Moisture 30–70 % — healthy range.
  ok,

  /// Moisture > 70 % — over-watered, pump should stop.
  wet,
}

extension MoistureStatusX on MoistureStatus {
  String get label => switch (this) {
        MoistureStatus.dry => 'DRY',
        MoistureStatus.ok => 'OK',
        MoistureStatus.wet => 'WET',
      };

  String get description => switch (this) {
        MoistureStatus.dry => 'Soil is dry — watering needed',
        MoistureStatus.ok => 'Soil moisture is in the healthy range',
        MoistureStatus.wet => 'Soil is sufficiently moist',
      };
}

class SensorReading {
  /// Soil moisture as a percentage [0.0 – 100.0].
  final double moisturePercent;

  /// Ambient temperature in °C. May be null if sensor not fitted.
  final double? temperatureCelsius;

  /// Water tank fill level as a percentage [0.0 – 100.0].
  final double tankLevelPercent;

  /// Whether the water pump is currently running (as reported by hardware).
  final bool isPumpRunning;

  /// UTC timestamp of the reading.
  final DateTime timestamp;

  /// Derived moisture status — computed from [moisturePercent].
  final MoistureStatus status;

  SensorReading({
    required this.moisturePercent,
    this.temperatureCelsius,
    required this.tankLevelPercent,
    required this.isPumpRunning,
    required this.timestamp,
  }) : status = _computeStatus(moisturePercent);

  static MoistureStatus _computeStatus(double pct) {
    if (pct < 30.0) return MoistureStatus.dry;
    if (pct > 70.0) return MoistureStatus.wet;
    return MoistureStatus.ok;
  }

  SensorReading copyWith({
    double? moisturePercent,
    double? temperatureCelsius,
    double? tankLevelPercent,
    bool? isPumpRunning,
    DateTime? timestamp,
  }) {
    return SensorReading(
      moisturePercent: moisturePercent ?? this.moisturePercent,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      tankLevelPercent: tankLevelPercent ?? this.tankLevelPercent,
      isPumpRunning: isPumpRunning ?? this.isPumpRunning,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
