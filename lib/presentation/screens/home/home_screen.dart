import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/moisture_gauge_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../providers/irrigation_provider.dart';
import 'widgets/pump_status_card.dart';
import 'widgets/sensor_stats_row.dart';
import 'widgets/tank_level_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dryAlertDismissed = false;
  bool _tankAlertDismissed = false;

  @override
  Widget build(BuildContext context) {
    final sensorAsync = ref.watch(sensorStreamProvider);
    final pumpAsync = ref.watch(pumpControlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fire snackbar once when crossing dry threshold from above
    ref.listen(sensorStreamProvider, (prev, next) {
      final cur = next.valueOrNull;
      final old = prev?.valueOrNull;
      if (cur == null) return;
      if (cur.moisturePercent < 30.0 &&
          (old == null || old.moisturePercent >= 30.0)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Soil moisture dropped below 30% — irrigation recommended!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.dry,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });

    return RefreshIndicator(
      color: AppColors.green600,
      onRefresh: () async {
        ref.invalidate(sensorStreamProvider);
        ref.invalidate(pumpControlProvider);
        setState(() {
          _dryAlertDismissed = false;
          _tankAlertDismissed = false;
        });
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.transparent,
            expandedHeight: 0,
            title: Row(
              children: [
                Icon(Icons.grass_rounded,
                    color: AppColors.green600, size: 24),
                const SizedBox(width: 8),
                const Text('Dashboard'),
              ],
            ),
            actions: [
              // Live update indicator
              sensorAsync.when(
                data: (_) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.ok,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ok,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),

          // ─── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: sensorAsync.when(
              loading: () => SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.green500),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting to sensor…',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Error reading sensor: $e',
                    style: const TextStyle(color: AppColors.dry),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (reading) {
                final isManual = pumpAsync.valueOrNull?.mode.name == 'manual';
                final isDry = reading.moisturePercent < 30.0;
                final isTankLow = reading.tankLevelPercent < 10.0;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Alert banners ───────────────────────────────────
                      if (isDry && !_dryAlertDismissed)
                        AlertBanner.dry(
                          onDismiss: () =>
                              setState(() => _dryAlertDismissed = true),
                        ),
                      if (isTankLow && !_tankAlertDismissed)
                        AlertBanner.tankLow(
                          onDismiss: () =>
                              setState(() => _tankAlertDismissed = true),
                        ),

                      const SizedBox(height: 16),

                      // ─── Moisture gauge ──────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            MoistureGaugeWidget(
                              moisturePercent: reading.moisturePercent,
                              status: reading.status,
                              size: 220,
                            ),
                            const SizedBox(height: 12),
                            StatusChip(
                                status: reading.status, fontSize: 13),
                            const SizedBox(height: 6),
                            Text(
                              reading.status.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── Pump + Tank row ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: PumpStatusCard(
                              isPumpRunning: reading.isPumpRunning,
                              isManualMode: isManual,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TankLevelCard(
                              tankLevelPercent: reading.tankLevelPercent,
                              isCritical: isTankLow,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ─── Stats row ───────────────────────────────────────
                      SensorStatsRow(
                        temperature: reading.temperatureCelsius,
                        flowRate: reading.flowRateLitersPerMin,
                        lastUpdated: reading.timestamp,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
