import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../providers/irrigation_provider.dart';
import 'widgets/moisture_chart_widget.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppColors.green600, size: 24),
              const SizedBox(width: 8),
              const Text('History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(historyProvider),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: historyAsync.when(
            loading: () => const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.green500),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.dry)),
              ),
            ),
            data: (readings) {
              if (readings.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No history available'),
                  ),
                );
              }

              final stats = _computeStats(readings);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Stats summary ───────────────────────────────────
                    _StatsRow(stats: stats, isDark: isDark),
                    const SizedBox(height: 20),

                    // ─── Chart card ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark2 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.green500.withAlpha(40)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green500.withAlpha(15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 20, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8, bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soil Moisture — Last 24 Hours',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _Legend(
                                        color: AppColors.green500,
                                        label: 'Moisture'),
                                    const SizedBox(width: 14),
                                    _Legend(
                                        color: AppColors.dry,
                                        label: 'Dry threshold (30%)',
                                        dashed: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 240,
                            child: MoistureChartWidget(readings: readings),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ─── Irrigation events ───────────────────────────────
                    _IrrigationEventsCard(readings: readings, isDark: isDark),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _HistoryStats _computeStats(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return _HistoryStats(avg: 0, min: 0, max: 0, pumpOnCount: 0);
    }
    double sum = 0;
    double min = double.infinity;
    double max = double.negativeInfinity;
    int pumpOn = 0;
    for (final r in readings) {
      sum += r.moisturePercent;
      if (r.moisturePercent < min) min = r.moisturePercent;
      if (r.moisturePercent > max) max = r.moisturePercent;
      if (r.isPumpRunning) pumpOn++;
    }
    return _HistoryStats(
      avg: sum / readings.length,
      min: min,
      max: max,
      pumpOnCount: pumpOn,
    );
  }
}

class _HistoryStats {
  final double avg, min, max;
  final int pumpOnCount;
  const _HistoryStats(
      {required this.avg,
      required this.min,
      required this.max,
      required this.pumpOnCount});
}

class _StatsRow extends StatelessWidget {
  final _HistoryStats stats;
  final bool isDark;

  const _StatsRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
            label: 'Avg',
            value: '${stats.avg.toStringAsFixed(1)}%',
            color: AppColors.ok,
            isDark: isDark),
        const SizedBox(width: 10),
        _StatTile(
            label: 'Min',
            value: '${stats.min.toStringAsFixed(1)}%',
            color: AppColors.dry,
            isDark: isDark),
        const SizedBox(width: 10),
        _StatTile(
            label: 'Max',
            value: '${stats.max.toStringAsFixed(1)}%',
            color: AppColors.wet,
            isDark: isDark),
        const SizedBox(width: 10),
        _StatTile(
            label: 'Pump On',
            value: '${stats.pumpOnCount}×',
            color: AppColors.green500,
            isDark: isDark),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;

  const _StatTile(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IrrigationEventsCard extends StatelessWidget {
  final List<SensorReading> readings;
  final bool isDark;

  const _IrrigationEventsCard(
      {required this.readings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Find irrigation start events (transition from OFF to ON)
    final events = <SensorReading>[];
    for (int i = 1; i < readings.length; i++) {
      if (!readings[i - 1].isPumpRunning && readings[i].isPumpRunning) {
        events.add(readings[i]);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green500.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Irrigation Events (${events.length})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'No irrigation events in this period.',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
            )
          else
            ...events.take(8).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(e.timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Moisture: ${e.moisturePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.dry,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}  $h:$m';
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _Legend(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        dashed
            ? Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 4,
                    height: 2,
                    margin: const EdgeInsets.only(right: 2),
                    color: color,
                  ),
                ),
              )
            : Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
