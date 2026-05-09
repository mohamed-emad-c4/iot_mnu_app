import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A card with subtle glassmorphic styling that adapts to light/dark mode.
///
/// Use this instead of raw [Card] to keep the IoT dashboard look consistent.
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.green500;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark ? AppColors.surfaceDark2 : Colors.white,
        border: Border.all(
          color: accent.withAlpha(isDark ? 50 : 30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(isDark ? 15 : 25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// A small metric tile used in the stats row.
class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = color ?? AppColors.green500;

    return GradientCard(
      accentColor: tileColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tileColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
