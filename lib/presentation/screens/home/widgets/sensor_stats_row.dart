import 'package:flutter/material.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/constants/app_colors.dart';

/// A horizontal row of 3 metric tiles: Temperature · Flow Rate · Last Updated.
class SensorStatsRow extends StatelessWidget {
  final double? temperature;
  final double flowRate;
  final DateTime lastUpdated;

  const SensorStatsRow({
    super.key,
    required this.temperature,
    required this.flowRate,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);
    final timeLabel = diff.inSeconds < 10
        ? 'Just now'
        : diff.inMinutes < 1
            ? '${diff.inSeconds}s ago'
            : '${diff.inMinutes}m ago';

    return Row(
      children: [
        Expanded(
          child: MetricTile(
            icon: Icons.thermostat_rounded,
            label: 'Temperature',
            value: temperature != null
                ? '${temperature!.toStringAsFixed(1)}°C'
                : '—',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            icon: Icons.water_rounded,
            label: 'Flow Rate',
            value: '${flowRate.toStringAsFixed(1)} L/m',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            icon: Icons.access_time_rounded,
            label: 'Updated',
            value: timeLabel,
            color: AppColors.green500,
          ),
        ),
      ],
    );
  }
}
