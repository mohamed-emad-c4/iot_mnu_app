import 'package:flutter/material.dart';
import '../../domain/entities/sensor_reading.dart';
import '../constants/app_colors.dart';

/// Pill-shaped badge that shows the moisture status label (DRY / OK / WET).
class StatusChip extends StatelessWidget {
  final MoistureStatus status;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  Color get _bg => switch (status) {
        MoistureStatus.dry => AppColors.dryLight,
        MoistureStatus.ok => AppColors.okLight,
        MoistureStatus.wet => AppColors.wetLight,
      };

  Color get _fg => switch (status) {
        MoistureStatus.dry => AppColors.dry,
        MoistureStatus.ok => AppColors.ok,
        MoistureStatus.wet => AppColors.wet,
      };

  IconData get _icon => switch (status) {
        MoistureStatus.dry => Icons.wb_sunny_rounded,
        MoistureStatus.ok => Icons.eco_rounded,
        MoistureStatus.wet => Icons.water_drop_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _fg.withAlpha(35) : _bg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: fontSize + 2, color: _fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _fg,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
