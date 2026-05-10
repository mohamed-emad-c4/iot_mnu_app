import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../setup/ip_setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final threshold = ref.watch(moistureThresholdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ip = ref.watch(espIpProvider);
    final wsStatus = ref.watch(wsStatusProvider);
    final cardColor = isDark ? AppColors.surfaceDark2 : Colors.white;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Icon(Icons.settings_rounded,
                  color: AppColors.green600, size: 24),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Appearance ──────────────────────────────────────────
                _SectionHeader('Appearance', isDark: isDark),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.green500.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      _ThemeTile(
                        label: 'System Default',
                        icon: Icons.brightness_auto_rounded,
                        selected: themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .state = ThemeMode.system,
                      ),
                      _Divider(),
                      _ThemeTile(
                        label: 'Light Mode',
                        icon: Icons.light_mode_rounded,
                        selected: themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .state = ThemeMode.light,
                      ),
                      _Divider(),
                      _ThemeTile(
                        label: 'Dark Mode',
                        icon: Icons.dark_mode_rounded,
                        selected: themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .state = ThemeMode.dark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Alerts ──────────────────────────────────────────────
                _SectionHeader('Alert Thresholds', isDark: isDark),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.green500.withAlpha(40)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded,
                              color: AppColors.dry, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Dry Alert Threshold',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${threshold.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dry,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Alert fires when moisture drops below this level.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Slider(
                        value: threshold,
                        min: 10,
                        max: 50,
                        divisions: 8,
                        activeColor: AppColors.dry,
                        inactiveColor: AppColors.dry.withAlpha(40),
                        onChanged: (val) => ref
                            .read(moistureThresholdProvider.notifier)
                            .state = val,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Connection ──────────────────────────────────────────
                _SectionHeader('Connection', isDark: isDark),
                _ConnectionCard(
                  ip: ip,
                  wsStatus: wsStatus,
                  isDark: isDark,
                  cardColor: cardColor,
                ),

                const SizedBox(height: 20),

                // ─── About ───────────────────────────────────────────────
                _SectionHeader('About', isDark: isDark),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.green500.withAlpha(40)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.green700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.grass_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Irrigation v1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Arduino / ESP8266 / ESP32 ready',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.green600,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: selected ? AppColors.green600 : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.green600, size: 20)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  final String? ip;
  final WsStatus wsStatus;
  final bool isDark;
  final Color cardColor;

  const _ConnectionCard({
    required this.ip,
    required this.wsStatus,
    required this.isDark,
    required this.cardColor,
  });

  (Color, String) _statusStyle() => switch (wsStatus) {
        WsStatus.connected => (AppColors.ok, 'CONNECTED'),
        WsStatus.connecting => (Colors.orange, 'CONNECTING'),
        WsStatus.error => (AppColors.dry, 'ERROR'),
        WsStatus.disconnected => (Colors.grey, 'OFFLINE'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusColor, statusLabel) = _statusStyle();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green500.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.wifi_rounded, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP32 WebSocket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      ip ?? '—',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Change IP button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IpSetupScreen()),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Change IP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green600,
                side: BorderSide(color: AppColors.green600),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
