import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/sensor_reading.dart';

/// Line chart visualising moisture percentage over the last 24 hours.
///
/// Uses fl_chart's [LineChart]. The x-axis represents time offsets in minutes
/// from the start of the data range; the y-axis shows moisture in percent.
class MoistureChartWidget extends StatefulWidget {
  final List<SensorReading> readings;

  const MoistureChartWidget({super.key, required this.readings});

  @override
  State<MoistureChartWidget> createState() => _MoistureChartWidgetState();
}

class _MoistureChartWidgetState extends State<MoistureChartWidget> {
  List<FlSpot> get _spots {
    if (widget.readings.isEmpty) return [];
    final first = widget.readings.first.timestamp.millisecondsSinceEpoch;
    return widget.readings
        .map(
          (r) => FlSpot(
            (r.timestamp.millisecondsSinceEpoch - first) / 3600000.0, // hours
            r.moisturePercent,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white54 : Colors.black38;
    final gridColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

    if (widget.readings.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No data available')),
      );
    }

    final spots = _spots;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.last.x,
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 25,
          verticalInterval: 6,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        // Dry / Wet threshold bands
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: 0,
              y2: 30,
              color: AppColors.dry.withAlpha(isDark ? 25 : 18),
            ),
            HorizontalRangeAnnotation(
              y1: 70,
              y2: 100,
              color: AppColors.wet.withAlpha(isDark ? 25 : 18),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 25,
              getTitlesWidget: (val, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '${val.toInt()}%',
                  style: TextStyle(fontSize: 10, color: textColor),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 6,
              getTitlesWidget: (val, _) {
                final label = val == 0
                    ? 'Start'
                    : '${val.toStringAsFixed(0)}h';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: textColor),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark3 : Colors.white,
            tooltipBorder: BorderSide(color: AppColors.green500.withAlpha(80)),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)}%\n',
                    const TextStyle(
                      color: AppColors.green500,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '${s.x.toStringAsFixed(1)}h elapsed',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.green500,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.green500.withAlpha(60),
                  AppColors.green500.withAlpha(0),
                ],
              ),
            ),
          ),
          // Dry threshold line at 30 %
          LineChartBarData(
            spots: [FlSpot(0, 30), FlSpot(spots.last.x, 30)],
            isCurved: false,
            color: AppColors.dry.withAlpha(180),
            barWidth: 1,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
