/// Domain entity that represents the user-facing control state of the pump.
///
/// [SensorReading.isPumpRunning] reflects what the hardware *actually* reports.
/// [PumpControl] reflects what the *user intends* (mode, manual request, speed).
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

  /// PWM duty cycle sent to the L298N motor driver [0 – 255].
  ///
  /// 0   = motor off (even if pump_on command was sent)
  /// 200 = default speed used by ESP32 firmware
  /// 255 = maximum speed
  final int pumpSpeed;

  /// When this control state was last changed by the user.
  final DateTime lastChanged;

  const PumpControl({
    required this.mode,
    required this.manualRunRequest,
    required this.pumpSpeed,
    required this.lastChanged,
  });

  PumpControl copyWith({
    IrrigationMode? mode,
    bool? manualRunRequest,
    int? pumpSpeed,
    DateTime? lastChanged,
  }) {
    return PumpControl(
      mode: mode ?? this.mode,
      manualRunRequest: manualRunRequest ?? this.manualRunRequest,
      pumpSpeed: pumpSpeed ?? this.pumpSpeed,
      lastChanged: lastChanged ?? this.lastChanged,
    );
  }

  factory PumpControl.initial() => PumpControl(
        mode: IrrigationMode.automatic,
        manualRunRequest: false,
        pumpSpeed: 200,
        lastChanged: DateTime.now(),
      );
}
