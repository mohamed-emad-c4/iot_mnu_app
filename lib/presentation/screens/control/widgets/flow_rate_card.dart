import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/pump_control.dart';
import '../../../providers/irrigation_provider.dart';

class PumpSpeedCard extends ConsumerWidget {
  const PumpSpeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpAsync = ref.watch(pumpControlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark2 : Colors.white;

    final pump = pumpAsync.valueOrNull;
    final isManual = pump?.mode == IrrigationMode.manual;
    final speed = pump?.pumpSpeed ?? 200;
    final dutyPct = (speed / 255 * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green500.withAlpha(40)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green500.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.speed_rounded,
                    color: AppColors.green600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pump Speed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      isManual
                          ? 'PWM duty: $dutyPct%'
                          : 'Switch to Manual to adjust',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isManual
                      ? AppColors.green500.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$speed / 255',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isManual ? AppColors.green600 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  isManual ? AppColors.green500 : Colors.grey.shade300,
              inactiveTrackColor: isManual
                  ? AppColors.green500.withAlpha(40)
                  : Colors.grey.shade200,
              thumbColor: isManual ? AppColors.green600 : Colors.grey,
              overlayColor: AppColors.green500.withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: speed.toDouble(),
              min: 0,
              max: 255,
              divisions: 51,
              onChanged: isManual
                  ? (val) => ref
                      .read(pumpControlProvider.notifier)
                      .setSpeed(val.round())
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Label('OFF', isManual),
                _Label('LOW', isManual),
                _Label('MED', isManual),
                _Label('HIGH', isManual),
                _Label('MAX', isManual),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool active;
  const _Label(this.text, this.active);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: active ? AppColors.green600 : Colors.grey.shade400,
      ),
    );
  }
}
