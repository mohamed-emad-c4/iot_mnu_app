import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/pump_control.dart';
import '../../providers/irrigation_provider.dart';
import 'widgets/flow_rate_card.dart';
import 'widgets/mode_toggle_card.dart';
import 'widgets/pump_toggle_card.dart';

class ControlScreen extends ConsumerWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pumpAsync = ref.watch(pumpControlProvider);
    final isManual =
        pumpAsync.valueOrNull?.mode == IrrigationMode.manual;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.green600, size: 24),
              const SizedBox(width: 8),
              const Text('Control'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Manual override warning ─────────────────────────────
                if (isManual)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.warning.withAlpha(80)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Manual override is active. Auto-irrigation is paused.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── Mode switch ─────────────────────────────────────────
                const ModeToggleCard(),
                const SizedBox(height: 14),

                // ─── Pump toggle ─────────────────────────────────────────
                const PumpToggleCard(),
                const SizedBox(height: 14),

                // ─── Flow rate ───────────────────────────────────────────
                const FlowRateCard(),
                const SizedBox(height: 14),

                // ─── Quick actions ───────────────────────────────────────
                _QuickActionsCard(isDark: isDark, ref: ref),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _QuickActionsCard({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green500.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '5-min Burst',
                  icon: Icons.timer_outlined,
                  color: AppColors.info,
                  onTap: () async {
                    // Switch to manual, run pump for 5 minutes
                    final notifier = ref.read(pumpControlProvider.notifier);
                    await notifier.setMode(IrrigationMode.manual);
                    await notifier.togglePump();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('5-minute burst started'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                    // In a real app: use a timer to turn off after 5 min
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Reset Auto',
                  icon: Icons.auto_mode_rounded,
                  color: AppColors.ok,
                  onTap: () async {
                    final notifier = ref.read(pumpControlProvider.notifier);
                    await notifier.setMode(IrrigationMode.automatic);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched back to automatic mode'),
                        backgroundColor: AppColors.ok,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
