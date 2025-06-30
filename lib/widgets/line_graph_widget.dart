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
  double _lastScale = 1.0;
  
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

  // Calculate the maximum width needed for Y-axis labels
  double _calculateMaxLabelWidth(BuildContext context) {
    if (!widget.isExpanded) return 0;
    
    final yAxisInterval = widget.yAxisDivisions != null 
        ? (_zoomedMaxY - _zoomedMinY) / widget.yAxisDivisions!
        : (_zoomedMaxY - _zoomedMinY) / 4;
    
    double maxWidth = 0;
    
    // Calculate width for each possible label
    for (double value = _zoomedMinY; value <= _zoomedMaxY; value += yAxisInterval) {
      if (value < _zoomedMinY || value > _zoomedMaxY) continue;
      
      final labelText = widget.yAxisFormatter != null 
          ? widget.yAxisFormatter!(value)
          : value.toStringAsFixed(1);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      maxWidth = maxWidth > textPainter.width ? maxWidth : textPainter.width;
      textPainter.dispose();
    }
    
    // Add padding (8 for right padding + 4 for safety margin)
    return maxWidth + 12;
  }

  // Get the sticky hour:minute labels info
  Map<String, dynamic> _getStickyTimeInfo() {
    final minX = _horizontalOffset;
    final maxX = (_horizontalOffset + _visibleDataPoints).clamp(0.0, widget.dataPoints.length - 1.0);
    
    String? currentStickyTime;
    String? nextStickyTime;
    double? nextStickyPosition;
    
    // Find the current sticky time (the minute that should be at the left edge)
    // Start from the leftmost visible point and go backwards to find the current minute
    String? currentMinute;
    for (int i = minX.floor(); i >= 0; i--) {
      if (i < widget.timestamps.length) {
        final time = widget.timestamps[i];
        final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        if (currentMinute == null) {
          currentMinute = timeStr;
          currentStickyTime = timeStr;
          break;
        }
      }
    }
    
    // If no current sticky time found, use the first visible timestamp
    if (currentStickyTime == null && minX.floor() < widget.timestamps.length) {
      final time = widget.timestamps[minX.floor()];
      currentStickyTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    
    // Find the next different minute that's visible
    for (int i = minX.ceil(); i <= maxX.ceil() && i < widget.timestamps.length; i++) {
      if (i < widget.timestamps.length) {
        final time = widget.timestamps[i];
        final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        if (timeStr != currentStickyTime) {
          nextStickyTime = timeStr;
          nextStickyPosition = i.toDouble();
          break;
        }
      }
    }
    
    return {
      'currentSticky': currentStickyTime,
      'nextSticky': nextStickyTime,
      'nextStickyPosition': nextStickyPosition,
      'minX': minX,
      'maxX': maxX,
    };
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
            ? (_zoomedMaxY - _zoomedMinY) / (_zoomLevel > 2.0 ? 6 : 4)  // More divisions when zoomed
            : (_zoomedMaxY - _zoomedMinY) / 4;
    
    // Add padding to prevent top value from being cut off
    final paddedMaxY = _zoomedMaxY + (_zoomedMaxY - _zoomedMinY) * 0.05;
    final paddedMinY = _zoomedMinY - (_zoomedMaxY - _zoomedMinY) * 0.05;

    // Calculate dynamic reserved size for Y-axis labels
    final reservedSize = widget.isExpanded ? _calculateMaxLabelWidth(context).clamp(40.0, 80.0) : 0.0;

    return Container(
      height: widget.isExpanded ? 220 : 60,
      padding: EdgeInsets.all(widget.isExpanded ? 16 : 8),
      child: widget.isExpanded 
          ? GestureDetector(
              onScaleStart: (details) {
                _lastScale = 1.0;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Handle zooming (when scale != 1.0)
                  if (details.scale != 1.0 && details.scale != _lastScale) {
                    final scaleChange = details.scale / _lastScale;
                    _zoomLevel = (_zoomLevel * scaleChange).clamp(1.0, 5.0);
                    _lastScale = details.scale;
                  }
                  // Handle panning (when there's focal point delta)
                  else if (details.focalPointDelta.dx != 0 || details.focalPointDelta.dy != 0) {
                    // Horizontal scrolling
                    if (details.focalPointDelta.dx.abs() > details.focalPointDelta.dy.abs()) {
                      _horizontalOffset -= details.focalPointDelta.dx / 10;
                      _horizontalOffset = _horizontalOffset.clamp(0.0, _maxHorizontalOffset);
                    } 
                    // Vertical panning when zoomed
                    else if (_zoomLevel > 1.0) {
                      final range = widget.maxY - widget.minY;
                      _verticalOffset += details.focalPointDelta.dy / 100 * range / _zoomLevel;
                      _verticalOffset = _verticalOffset.clamp(-range, range);
                    }
                  }
                });
              },
              child: _buildChart(spots, yAxisInterval, paddedMaxY, paddedMinY, reservedSize),
            )
          : _buildChart(spots, yAxisInterval, paddedMaxY, paddedMinY, reservedSize),
    );
  }

  Widget _buildChart(List<FlSpot> spots, double yAxisInterval, double paddedMaxY, double paddedMinY, double reservedSize) {
    // Calculate visible range for horizontal scrolling
    final minX = widget.isExpanded ? _horizontalOffset : 0.0;
    final maxX = widget.isExpanded 
        ? (_horizontalOffset + _visibleDataPoints).clamp(0.0, widget.dataPoints.length - 1.0)
        : (widget.dataPoints.length - 1).toDouble();

    // Filter spots to only include visible ones + slight buffer for smooth scrolling
    final visibleSpots = widget.isExpanded 
        ? spots.where((spot) => spot.x >= minX - 1 && spot.x <= maxX + 1).toList()
        : spots;

    // Get sticky time info
    final stickyInfo = widget.isExpanded ? _getStickyTimeInfo() : null;

    return Stack(
      children: [
        // Main chart
        LineChart(
          LineChartData(
            clipData: FlClipData.all(), // This is crucial - clips everything to chart bounds
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
                    
                    // Hide edge values (first and last visible points)
                    if (index == minX.toInt() || index == maxX.toInt()) {
                      return const SizedBox.shrink();
                    }
                    
                    if (index >= 0 && index < widget.timestamps.length) {
                      final time = widget.timestamps[index];
                      final second = time.second.toString().padLeft(2, '0');
                      
                      return SideTitleWidget(
                        meta: meta,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Seconds on top
                            Text(
                              second,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            // Empty space for hour:minute (handled by overlay)
                            const SizedBox(height: 12),
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
                  reservedSize: reservedSize,
                  getTitlesWidget: (value, meta) {
                    // Only show labels that are within the original range to avoid padding labels
                    if (value < _zoomedMinY || value > _zoomedMaxY) {
                      return const SizedBox.shrink();
                    }
                    
                    final labelText = widget.yAxisFormatter != null 
                        ? widget.yAxisFormatter!(value)
                        : value.toStringAsFixed(1);
                    
                    return SideTitleWidget(
                      meta: meta,
                      child: Container(
                        width: reservedSize - 8, // Account for right padding
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          labelText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.clip, // Changed from ellipsis to clip
                          maxLines: 1,
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
                spots: visibleSpots, // Use filtered spots
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
        ),
        
        // Sticky time labels overlay
        if (widget.isExpanded && stickyInfo != null)
          Positioned(
            left: reservedSize, // Start after Y-axis
            right: 0,
            bottom: 12, // Position it higher, aligned with the seconds row
            height: 12, // Height for just the time text
            child: _buildStickyTimeOverlay(stickyInfo, minX, maxX, reservedSize),
          ),
        
        // Additional clipping overlay for Y-axis area (extra safety)
        if (widget.isExpanded)
          Positioned(
            left: 0,
            top: 0,
            bottom: 50, // Account for bottom titles
            width: reservedSize,
            child: Container(
              color: Colors.transparent,
              child: ClipRect(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickyTimeOverlay(Map<String, dynamic> stickyInfo, double minX, double maxX, double reservedSize) {
    final currentSticky = stickyInfo['currentSticky'] as String?;
    final nextSticky = stickyInfo['nextSticky'] as String?;
    final nextStickyPosition = stickyInfo['nextStickyPosition'] as double?;
    
    // Calculate chart width (excluding Y-axis)
    final chartWidth = MediaQuery.of(context).size.width - 32 - reservedSize; // Account for padding
    
    return Stack(
      children: [
        // Current sticky time (always at left edge)
        if (currentSticky != null)
          Positioned(
            left: 0, // Always at the left edge
            bottom: 0,
            child: Text(
              currentSticky,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        
        // Next sticky time (moving with its position until it reaches left edge)
        if (nextSticky != null && nextStickyPosition != null && nextSticky != currentSticky)
          Positioned(
            left: _calculateStickyPosition(nextStickyPosition, minX, maxX, chartWidth).clamp(0.0, double.infinity),
            bottom: 0,
            child: Text(
              nextSticky,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  double _calculateStickyPosition(double dataPosition, double minX, double maxX, double chartWidth) {
    // Calculate the relative position within the visible range
    final relativePosition = (dataPosition - minX) / (maxX - minX);
    final pixelPosition = relativePosition * chartWidth;
    
    // Return the actual position - it will be clamped in the Positioned widget
    return pixelPosition;
  }
}