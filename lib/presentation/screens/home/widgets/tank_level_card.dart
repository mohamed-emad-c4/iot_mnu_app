import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Vertical tank-fill visualisation for the water reservoir level.
class TankLevelCard extends StatelessWidget {
  final double tankLevelPercent; // 0.0 – 100.0
  final bool isCritical;

  const TankLevelCard({
    super.key,
    required this.tankLevelPercent,
    required this.isCritical,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isCritical ? AppColors.warning : AppColors.info;
    final bg = isDark ? AppColors.surfaceDark2 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fillColor.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: fillColor.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_outlined,
                size: 18,
                color: fillColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Tank Level',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              if (isCritical) ...[
                const Spacer(),
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Tank bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: (tankLevelPercent / 100).clamp(0.0, 1.0),
                backgroundColor: fillColor.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${tankLevelPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: fillColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
