import 'dart:async';

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

                // ─── Pump speed ──────────────────────────────────────────
                const PumpSpeedCard(),
                const SizedBox(height: 14),

                // ─── Quick actions ───────────────────────────────────────
                const _QuickActionsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Uses StatefulWidget to hold the burst timer without a global provider.
class _QuickActionsCard extends ConsumerStatefulWidget {
  const _QuickActionsCard();

  @override
  ConsumerState<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<_QuickActionsCard> {
  Timer? _burstTimer;
  int _burstSecondsLeft = 0;

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  Future<void> _startBurst() async {
    final notifier = ref.read(pumpControlProvider.notifier);
    await notifier.setMode(IrrigationMode.manual);

    final pump = ref.read(pumpControlProvider).valueOrNull;
    if (pump != null && !pump.manualRunRequest) {
      await notifier.togglePump();
    }

    setState(() => _burstSecondsLeft = 300); // 5 minutes

    _burstTimer?.cancel();
    _burstTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      setState(() => _burstSecondsLeft--);
      if (_burstSecondsLeft <= 0) {
        t.cancel();
        await ref.read(pumpControlProvider.notifier).togglePump();
        await ref.read(pumpControlProvider.notifier).setMode(IrrigationMode.automatic);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('5-minute burst complete — auto mode restored'),
              backgroundColor: AppColors.ok,
            ),
          );
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('5-minute burst started'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  String get _burstLabel {
    if (_burstSecondsLeft <= 0) return '5-min Burst';
    final m = _burstSecondsLeft ~/ 60;
    final s = _burstSecondsLeft % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBursting = _burstSecondsLeft > 0;

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
                  label: _burstLabel,
                  icon: isBursting ? Icons.timer : Icons.timer_outlined,
                  color: isBursting ? AppColors.warning : AppColors.info,
                  onTap: isBursting ? null : _startBurst,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Reset Auto',
                  icon: Icons.auto_mode_rounded,
                  color: AppColors.ok,
                  onTap: () async {
                    _burstTimer?.cancel();
                    setState(() => _burstSecondsLeft = 0);
                    await ref
                        .read(pumpControlProvider.notifier)
                        .setMode(IrrigationMode.automatic);
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
  final VoidCallback? onTap;

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
          color: color.withAlpha(onTap == null ? 10 : 20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(onTap == null ? 40 : 80)),
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
