import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/pump_control.dart';
import '../../../providers/irrigation_provider.dart';

/// Card that switches between Automatic and Manual irrigation modes.
class ModeToggleCard extends ConsumerWidget {
  const ModeToggleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpAsync = ref.watch(pumpControlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark2 : Colors.white;

    return pumpAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (control) {
        final isAuto = control.mode == IrrigationMode.automatic;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.green500.withAlpha(40),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAuto ? Icons.auto_mode_rounded : Icons.tune_rounded,
                    color: AppColors.green600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Irrigation Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isAuto,
                    onChanged: (val) {
                      ref.read(pumpControlProvider.notifier).setMode(
                            val
                                ? IrrigationMode.automatic
                                : IrrigationMode.manual,
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mode selection chips
              Row(
                children: [
                  _ModeChip(
                    label: 'Automatic',
                    icon: Icons.auto_mode_rounded,
                    selected: isAuto,
                    onTap: () => ref
                        .read(pumpControlProvider.notifier)
                        .setMode(IrrigationMode.automatic),
                  ),
                  const SizedBox(width: 10),
                  _ModeChip(
                    label: 'Manual',
                    icon: Icons.tune_rounded,
                    selected: !isAuto,
                    onTap: () => ref
                        .read(pumpControlProvider.notifier)
                        .setMode(IrrigationMode.manual),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAuto
                      ? AppColors.ok.withAlpha(20)
                      : AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAuto
                        ? AppColors.ok.withAlpha(60)
                        : AppColors.warning.withAlpha(60),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAuto
                          ? Icons.info_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: isAuto ? AppColors.ok : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAuto
                            ? control.mode.description
                            : '${control.mode.description}. Auto-irrigation is paused.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuto ? AppColors.ok : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green600 : Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green500.withAlpha(isDark ? 50 : 30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(selected ? 120 : 50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
