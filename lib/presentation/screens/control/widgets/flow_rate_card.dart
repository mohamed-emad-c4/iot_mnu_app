import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../providers/irrigation_provider.dart';

/// Card that exposes flow rate control.
///
/// Hardware mapping:
///   - Relay (binary): any rate > 0 → full ON. Rate shown for info only.
///   - MOSFET/PWM    : rate × 255 → analogWrite duty cycle.
///   - Peristaltic pump with driver: map rate to RPM setpoint.
class FlowRateCard extends ConsumerWidget {
  const FlowRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpAsync = ref.watch(pumpControlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark2 : Colors.white;

    return pumpAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (control) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.info.withAlpha(40)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_rounded,
                      color: AppColors.info, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Flow Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(control.flowRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(control.flowRate * 4.8).toStringAsFixed(1)} L/min (max 4.8 L/min)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: control.flowRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (val) {
                  ref.read(pumpControlProvider.notifier).setFlowRate(val);
                },
              ),
              // Tick labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Low', 'Medium', 'High']
                      .map(
                        (l) => Text(
                          l,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
