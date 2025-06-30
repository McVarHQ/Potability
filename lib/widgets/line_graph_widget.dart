import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineGraphWidget extends StatefulWidget {
  final List<double> dataPoints;
  final List<DateTime> timestamps;
  final String label;
  final Color lineColor;
  final bool isExpanded;
  final double minY;
  final double maxY;
  final String Function(double)? yAxisFormatter;
  final int? yAxisDivisions;

  const LineGraphWidget({
    super.key,
    required this.dataPoints,
    required this.timestamps,
    required this.label,
    required this.lineColor,
    this.isExpanded = false,
    this.minY = 0,
    this.maxY = 100,
    this.yAxisFormatter,
    this.yAxisDivisions,
  });

  @override
  State<LineGraphWidget> createState() => _LineGraphWidgetState();
}

class _LineGraphWidgetState extends State<LineGraphWidget> {
  double _horizontalOffset = 0.0;
  double _zoomLevel = 1.0;
  double _verticalOffset = 0.0;
  
  // How many data points to show at once when expanded
  static const int _visibleDataPoints = 10;
  
  double get _maxHorizontalOffset => 
      (widget.dataPoints.length - _visibleDataPoints).toDouble().clamp(0.0, double.infinity);
  
  double get _zoomedMinY {
    final range = widget.maxY - widget.minY;
    final zoomedRange = range / _zoomLevel;
    final center = widget.minY + range / 2 + _verticalOffset;
    return (center - zoomedRange / 2).clamp(widget.minY - range, widget.maxY + range);
  }
  
  double get _zoomedMaxY {
    final range = widget.maxY - widget.minY;
    final zoomedRange = range / _zoomLevel;
    final center = widget.minY + range / 2 + _verticalOffset;
    return (center + zoomedRange / 2).clamp(widget.minY - range, widget.maxY + range);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return SizedBox(
        height: widget.isExpanded ? 220 : 60,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: widget.isExpanded ? 14 : 10,
            ),
          ),
        ),
      );
    }

    final spots = widget.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    // Calculate interval for Y-axis based on provided divisions or default
    final yAxisInterval = widget.yAxisDivisions != null 
        ? (_zoomedMaxY - _zoomedMinY) / widget.yAxisDivisions!
        : widget.isExpanded 
            ? (_zoomedMaxY - _zoomedMinY) / 4  // Use 4 divisions for expanded view
            : (_zoomedMaxY - _zoomedMinY) / 4;
    
    // Add padding to prevent top value from being cut off
    final paddedMaxY = _zoomedMaxY + (_zoomedMaxY - _zoomedMinY) * 0.05;
    final paddedMinY = _zoomedMinY - (_zoomedMaxY - _zoomedMinY) * 0.05;

    return Container(
      height: widget.isExpanded ? 220 : 60,
      padding: EdgeInsets.all(widget.isExpanded ? 16 : 8),
      child: widget.isExpanded 
          ? GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Horizontal scrolling
                  if (details.delta.dx.abs() > details.delta.dy.abs()) {
                    _horizontalOffset -= details.delta.dx / 10;
                    _horizontalOffset = _horizontalOffset.clamp(0.0, _maxHorizontalOffset);
                  } 
                  // Vertical panning when zoomed
                  else if (_zoomLevel > 1.0) {
                    final range = widget.maxY - widget.minY;
                    _verticalOffset += details.delta.dy / 100 * range / _zoomLevel;
                    _verticalOffset = _verticalOffset.clamp(-range, range);
                  }
                });
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Only allow vertical zoom
                  if (details.scale != 1.0) {
                    _zoomLevel = (_zoomLevel * details.scale).clamp(1.0, 5.0);
                  }
                });
              },
              child: _buildChart(spots, yAxisInterval, paddedMaxY, paddedMinY),
            )
          : _buildChart(spots, yAxisInterval, paddedMaxY, paddedMinY),
    );
  }

  Widget _buildChart(List<FlSpot> spots, double yAxisInterval, double paddedMaxY, double paddedMinY) {
    // Calculate visible range for horizontal scrolling
    final minX = widget.isExpanded ? _horizontalOffset : 0.0;
    final maxX = widget.isExpanded 
        ? (_horizontalOffset + _visibleDataPoints).clamp(0.0, widget.dataPoints.length - 1.0)
        : (widget.dataPoints.length - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: widget.isExpanded,
          drawVerticalLine: widget.isExpanded,
          horizontalInterval: widget.isExpanded ? yAxisInterval : null,
          verticalInterval: widget.isExpanded ? 1 : null,
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
          show: widget.isExpanded,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: widget.isExpanded,
              reservedSize: 50,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.timestamps.length) {
                  final time = widget.timestamps[index];
                  final minute = time.minute.toString().padLeft(2, '0');
                  final hour = time.hour.toString().padLeft(2, '0');
                  
                  // Show hour only when it changes or for first/last items in visible range
                  String hourText = '';
                  if (index == minX.toInt() || 
                      index == maxX.toInt() || 
                      (index > 0 && index < widget.timestamps.length && 
                       widget.timestamps[index - 1].hour != time.hour)) {
                    hourText = hour;
                  }
                  
                  return SideTitleWidget(
                    meta: meta,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minutes on top
                        Text(
                          minute,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        // Hours on bottom (only when changes)
                        SizedBox(
                          height: 12,
                          child: hourText.isNotEmpty
                              ? Text(
                                  hourText,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: widget.isExpanded,
              interval: yAxisInterval,
              reservedSize: widget.isExpanded ? 75 : 60,
              getTitlesWidget: (value, meta) {
                // Only show labels that are within the original range to avoid padding labels
                if (value < _zoomedMinY || value > _zoomedMaxY) {
                  return const SizedBox.shrink();
                }
                
                return SideTitleWidget(
                  meta: meta,
                  child: Container(
                    width: widget.isExpanded ? 65 : 50,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(
                      right: widget.isExpanded ? 10.0 : 8.0,
                    ),
                    child: Text(
                      widget.yAxisFormatter != null 
                          ? widget.yAxisFormatter!(value)
                          : value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: widget.isExpanded,
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        minX: minX,
        maxX: maxX,
        minY: paddedMinY,
        maxY: paddedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                widget.lineColor.withOpacity(0.8),
                widget.lineColor,
              ],
            ),
            barWidth: widget.isExpanded ? 3 : 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: widget.isExpanded,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: widget.lineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: !widget.isExpanded,
              gradient: LinearGradient(
                colors: [
                  widget.lineColor.withOpacity(0.3),
                  widget.lineColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: widget.isExpanded,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueAccent,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final index = flSpot.x.toInt();
                if (index >= 0 && index < widget.timestamps.length) {
                  final time = widget.timestamps[index];
                  final valueText = widget.yAxisFormatter != null 
                      ? '${widget.yAxisFormatter!(flSpot.y)} (${flSpot.y.toStringAsFixed(2)})'
                      : flSpot.y.toStringAsFixed(2);
                  return LineTooltipItem(
                    '$valueText\n${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
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
    );
  }
}