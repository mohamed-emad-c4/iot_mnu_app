import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/pump_control.dart';
import '../../../providers/irrigation_provider.dart';

/// Large circular pump toggle button with animated state feedback.
class PumpToggleCard extends ConsumerWidget {
  const PumpToggleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorStreamProvider);
    final pumpAsync = ref.watch(pumpControlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isRunning = sensorAsync.valueOrNull?.isPumpRunning ?? false;
    final isManual = pumpAsync.valueOrNull?.mode == IrrigationMode.manual;
    final isLoading = pumpAsync.isLoading;

    final buttonColor = isRunning ? AppColors.ok : Colors.grey.shade400;
    final bgColor = isDark ? AppColors.surfaceDark2 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: buttonColor.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Pump Control',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isManual
                ? 'Manual override active'
                : 'Switch to Manual to control',
            style: TextStyle(
              fontSize: 12,
              color: isManual
                  ? AppColors.warning
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          const SizedBox(height: 28),
          // ─── Big toggle button ───────────────────────────────────────────
          GestureDetector(
            onTap: isManual && !isLoading
                ? () async {
                    await ref
                        .read(pumpControlProvider.notifier)
                        .togglePump();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isManual
                    ? (isRunning
                        ? AppColors.ok
                        : (isDark
                            ? AppColors.surfaceDark3
                            : Colors.grey.shade100))
                    : (isDark ? AppColors.surfaceDark3 : Colors.grey.shade100),
                boxShadow: isManual && isRunning
                    ? [
                        BoxShadow(
                          color: AppColors.ok.withAlpha(80),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: isManual ? buttonColor : Colors.grey.withAlpha(60),
                  width: 3,
                ),
              ),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.green500,
                        strokeWidth: 3,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 42,
                          color: isManual
                              ? (isRunning ? Colors.white : buttonColor)
                              : Colors.grey.withAlpha(100),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRunning ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isManual
                                ? (isRunning ? Colors.white : buttonColor)
                                : Colors.grey.withAlpha(100),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRunning ? 'Pump is running' : 'Pump is stopped',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: buttonColor,
            ),
          ),
        ],
      ),
    );
  }
}
