import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/sensor_reading.dart';
import '../constants/app_colors.dart';

/// Animated circular arc gauge that visualises the soil moisture level.
///
/// Draws a 270° arc track; the filled portion scales with [moisturePercent].
/// The arc colour smoothly transitions from red (dry) through amber to green (wet).
class MoistureGaugeWidget extends StatefulWidget {
  final double moisturePercent; // 0.0 – 100.0
  final MoistureStatus status;
  final double size;

  const MoistureGaugeWidget({
    super.key,
    required this.moisturePercent,
    required this.status,
    this.size = 220,
  });

  @override
  State<MoistureGaugeWidget> createState() => _MoistureGaugeWidgetState();
}

class _MoistureGaugeWidgetState extends State<MoistureGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: widget.moisturePercent / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _prevValue = widget.moisturePercent / 100;
  }

  @override
  void didUpdateWidget(MoistureGaugeWidget old) {
    super.didUpdateWidget(old);
    if (old.moisturePercent != widget.moisturePercent) {
      _anim = Tween<double>(
        begin: _prevValue,
        end: widget.moisturePercent / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
      _prevValue = widget.moisturePercent / 100;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _gaugeColor => switch (widget.status) {
        MoistureStatus.dry => AppColors.dry,
        MoistureStatus.ok => AppColors.ok,
        MoistureStatus.wet => AppColors.wet,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(12);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              value: _anim.value,
              trackColor: trackColor,
              fillColor: _gaugeColor,
              strokeWidth: widget.size * 0.072,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.moisturePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.155,
                      fontWeight: FontWeight.w800,
                      color: _gaugeColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MOISTURE',
                    style: TextStyle(
                      fontSize: widget.size * 0.058,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black38,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  const _GaugePainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  static const double _startDeg = 135.0;
  static const double _sweepDeg = 270.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = trackColor;
    canvas.drawArc(
      rect,
      _toRad(_startDeg),
      _toRad(_sweepDeg),
      false,
      paint,
    );

    // Filled arc
    if (value > 0) {
      paint.color = fillColor;
      canvas.drawArc(
        rect,
        _toRad(_startDeg),
        _toRad(_sweepDeg * value),
        false,
        paint,
      );
    }
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.fillColor != fillColor;
}
