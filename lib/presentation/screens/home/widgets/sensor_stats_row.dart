import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../providers/irrigation_provider.dart';

/// A horizontal row of 3 metric tiles: Temperature · Pump Speed · Last Updated.
class SensorStatsRow extends ConsumerWidget {
  final double? temperature;
  final DateTime lastUpdated;

  const SensorStatsRow({
    super.key,
    required this.temperature,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpSpeed =
        ref.watch(pumpControlProvider).valueOrNull?.pumpSpeed ?? 0;

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
            icon: Icons.speed_rounded,
            label: 'Pump Speed',
            value: '$pumpSpeed / 255',
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
