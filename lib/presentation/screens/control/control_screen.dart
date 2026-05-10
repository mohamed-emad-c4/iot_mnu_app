import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/irrigation_provider.dart';
import '../../../domain/entities/pump_control.dart';
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
