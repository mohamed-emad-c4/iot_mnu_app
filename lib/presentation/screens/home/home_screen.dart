import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/moisture_gauge_widget.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../setup/ip_setup_screen.dart';
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
              loading: () => _NoConnectionView(isDark: isDark),
              error: (e, st) => _NoConnectionView(isDark: isDark),

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

class _NoConnectionView extends ConsumerWidget {
  final bool isDark;
  const _NoConnectionView({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsStatus = ref.watch(wsStatusProvider);
    final ip = ref.watch(espIpProvider) ?? '—';

    final isConnecting = wsStatus == WsStatus.connecting ||
        wsStatus == WsStatus.disconnected;

    return SizedBox(
      height: 420,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon or spinner
              if (isConnecting)
                const CircularProgressIndicator(color: AppColors.green500)
              else
                Icon(Icons.wifi_off_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26),

              const SizedBox(height: 20),

              Text(
                isConnecting ? 'Connecting to ESP32…' : 'Cannot reach ESP32',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isConnecting
                    ? 'Waiting for data from $ip'
                    : 'Make sure your phone is connected\nto the ESP32 Wi-Fi (SmartIrrigation)\nand the device is powered on.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),

              // Retry hint — only shown when actually failed
              if (!isConnecting) ...[
                const SizedBox(height: 8),
                Text(
                  'Auto-retrying in the background…',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Retry button — force a new WebSocket attempt now
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(irrigationServiceProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green600,
                  side: BorderSide(color: AppColors.green600),
                ),
              ),

              const SizedBox(height: 10),

              // Change IP shortcut
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IpSetupScreen(),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text('Change IP  ($ip)'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white38 : Colors.black38,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
