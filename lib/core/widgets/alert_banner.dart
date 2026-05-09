import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// In-app alert banner shown at the top of the screen when the soil is
/// critically dry or the water tank is low.
class AlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.color = AppColors.warning,
    this.onDismiss,
  });

  factory AlertBanner.dry({VoidCallback? onDismiss}) => AlertBanner(
        message: 'Soil is critically dry! Watering is recommended.',
        icon: Icons.wb_sunny_rounded,
        color: AppColors.dry,
        onDismiss: onDismiss,
      );

  factory AlertBanner.tankLow({VoidCallback? onDismiss}) => AlertBanner(
        message: 'Water tank level is critically low!',
        icon: Icons.water_drop_outlined,
        color: AppColors.warning,
        onDismiss: onDismiss,
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 18, color: color),
            ),
        ],
      ),
    );
  }
}
