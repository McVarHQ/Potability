import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineGraphWidget extends StatelessWidget {
  final List<double> dataPoints;
  final List<DateTime> timestamps;
  final String label;
  final Color lineColor;
  final bool isExpanded;
  final double minY;
  final double maxY;

  const LineGraphWidget({
    super.key,
    required this.dataPoints,
    required this.timestamps,
    required this.label,
    required this.lineColor,
    this.isExpanded = false,
    this.minY = 0,
    this.maxY = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: isExpanded ? 200 : 60,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isExpanded ? 14 : 10,
            ),
          ),
        ),
      );
    }

    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return Container(
      height: isExpanded ? 200 : 60,
      padding: EdgeInsets.all(isExpanded ? 16 : 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: isExpanded,
            drawVerticalLine: isExpanded,
            horizontalInterval: isExpanded ? (maxY - minY) / 4 : null,
            verticalInterval: isExpanded ? 1 : null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: isExpanded,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: isExpanded,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < timestamps.length) {
                    final time = timestamps[index];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: isExpanded,
                interval: (maxY - minY) / 4,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: isExpanded,
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.8),
                  lineColor,
                ],
              ),
              barWidth: isExpanded ? 3 : 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: isExpanded,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: !isExpanded,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0.3),
                    lineColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: isExpanded,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueAccent,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final index = flSpot.x.toInt();
                  if (index >= 0 && index < timestamps.length) {
                    final time = timestamps[index];
                    return LineTooltipItem(
                      '${flSpot.y.toStringAsFixed(2)}\n${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}