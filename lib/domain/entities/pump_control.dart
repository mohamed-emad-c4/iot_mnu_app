/// Domain entity that represents the user-facing control state of the pump.
///
/// [SensorReading.isPumpRunning] reflects what the hardware *actually* reports.
/// [PumpControl] reflects what the *user intends* (mode, manual request, flow rate).
library;

/// Determines who decides when the pump runs.
enum IrrigationMode {
  /// The microcontroller/app logic decides based on moisture threshold.
  automatic,

  /// The user has manually overridden the pump state.
  manual,
}

extension IrrigationModeX on IrrigationMode {
  String get label =>
      this == IrrigationMode.automatic ? 'Automatic' : 'Manual';

  String get description => this == IrrigationMode.automatic
      ? 'Pump is controlled automatically by moisture threshold'
      : 'You are manually controlling the pump';
}

class PumpControl {
  /// Current operating mode.
  final IrrigationMode mode;

  /// Manual pump on/off request (only respected in manual mode).
  final bool manualRunRequest;

  /// Flow rate as a fraction [0.0 – 1.0] of the pump's maximum capacity.
  ///
  /// Map to hardware:
  ///   - Relay (on/off only): treat any value > 0 as ON.
  ///   - MOSFET / PWM: multiply by 255 for analogWrite duty cycle.
  final double flowRate;

  /// When this control state was last changed by the user.
  final DateTime lastChanged;

  const PumpControl({
    required this.mode,
    required this.manualRunRequest,
    required this.flowRate,
    required this.lastChanged,
  });

  PumpControl copyWith({
    IrrigationMode? mode,
    bool? manualRunRequest,
    double? flowRate,
    DateTime? lastChanged,
  }) {
    return PumpControl(
      mode: mode ?? this.mode,
      manualRunRequest: manualRunRequest ?? this.manualRunRequest,
      flowRate: flowRate ?? this.flowRate,
      lastChanged: lastChanged ?? this.lastChanged,
    );
  }

  factory PumpControl.initial() => PumpControl(
        mode: IrrigationMode.automatic,
        manualRunRequest: false,
        flowRate: 0.6,
        lastChanged: DateTime.now(),
      );
}
