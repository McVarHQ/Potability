import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:potability/widgets/line_graph_widget.dart';

const aqua = Color(0xFF00BCD4);

class ExpandableTile extends StatefulWidget {
  final String label;
  final String value;
  final String iconPath;
  final bool isExpanded;
  final bool isShrunken;
  final VoidCallback onTap;
  final List<double> dataPoints;
  final List<DateTime> timestamps;
  final Color lineColor;
  final bool isResultTile;
  final String? predictionResult;
  final bool predicting;
  final Widget? predictionContent;

  const ExpandableTile({
    super.key,
    required this.label,
    required this.value,
    required this.iconPath,
    required this.isExpanded,
    required this.isShrunken,
    required this.onTap,
    required this.dataPoints,
    required this.timestamps,
    this.lineColor = aqua,
    this.isResultTile = false,
    this.predictionResult,
    this.predicting = false,
    this.predictionContent,
  });

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double get minY {
    if (widget.dataPoints.isEmpty) return 0;
    if (widget.isResultTile) return -0.1;
    final min = widget.dataPoints.reduce((a, b) => a < b ? a : b);
    return (min - (min * 0.1)).clamp(0, double.infinity);
  }

  double get maxY {
    if (widget.dataPoints.isEmpty) return 100;
    if (widget.isResultTile) return 1.1;
    final max = widget.dataPoints.reduce((a, b) => a > b ? a : b);
    return max + (max * 0.1);
  }

  // Helper method to format Y-axis values for better readability
  String _formatYAxisValue(double value) {
    if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else if (value >= 100) {
      return value.toStringAsFixed(0);
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  // Helper method to get optimal number of Y-axis divisions
  int _getOptimalYAxisDivisions() {
    if (widget.dataPoints.isEmpty) return 4;
    
    // For expanded view, use 4 divisions for good spacing
    if (widget.isExpanded) {
      return 4; // Use 4 divisions for expanded view
    }
    
    // For compact view, can use more divisions since they're not shown
    final range = maxY - minY;
    if (range > 50000) return 4;
    if (range > 10000) return 5;
    if (range > 1000) return 6;
    return 8;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.predicting) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExpandableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.predicting && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.predicting && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.isExpanded ? double.infinity : null,
        height: widget.isExpanded ? 300 : (widget.isShrunken ? 80 : 140),
        margin: EdgeInsets.all(widget.isExpanded ? 0 : 4),
        padding: EdgeInsets.all(widget.isExpanded ? 16 : 12),
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(widget.isExpanded ? 20 : 16),
          border: Border.all(
            color: _getBorderColor(),
            width: widget.isExpanded ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(),
              blurRadius: widget.isExpanded ? 20 : 12,
              offset: Offset(0, widget.isExpanded ? 8 : 4),
            ),
            if (!widget.isShrunken)
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
          ],
        ),
        child: widget.isExpanded ? _buildExpandedContent() : _buildCompactContent(),
      ),
    );
  }

  LinearGradient _getGradient() {
    if (widget.isResultTile && widget.predictionResult != null) {
      final isError = widget.predictionResult!.toLowerCase().contains("error");
      final isPotable = widget.predictionResult == "Potable";
      
      if (isError) {
        return LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (isPotable) {
        return LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return LinearGradient(
          colors: [Colors.red.shade100, Colors.red.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        const Color(0xFFE0F7FA).withOpacity(0.8),
        Colors.white.withOpacity(0.9),
      ],
    );
  }

  Color _getBorderColor() {
    if (widget.isResultTile && widget.predictionResult != null) {
      final isError = widget.predictionResult!.toLowerCase().contains("error");
      final isPotable = widget.predictionResult == "Potable";
      
      if (isError) return Colors.orange.shade200;
      if (isPotable) return Colors.green.shade200;
      return Colors.red.shade200;
    }
    
    return aqua.withOpacity(widget.isExpanded ? 0.6 : 0.3);
  }

  Color _getShadowColor() {
    if (widget.isResultTile && widget.predictionResult != null) {
      final isError = widget.predictionResult!.toLowerCase().contains("error");
      final isPotable = widget.predictionResult == "Potable";
      
      if (isError) return Colors.orange.withOpacity(0.2);
      if (isPotable) return Colors.green.withOpacity(0.2);
      return Colors.red.withOpacity(0.2);
    }
    
    return aqua.withOpacity(widget.isExpanded ? 0.3 : 0.15);
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isResultTile ? _getResultColor() : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: widget.isResultTile ? _getShadowColor() : widget.lineColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _buildIcon(24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (!widget.isResultTile)
                    Text(
                      'Current: ${widget.value}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (widget.isResultTile && widget.predictionResult != null && !widget.predicting)
                    Text(
                      'Result: ${widget.predictionResult!.startsWith("Prediction error") ? "Error" : widget.predictionResult!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getResultTextColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (widget.isResultTile && widget.predicting)
                    Text(
                      'Predicting...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onTap,
              icon: const Icon(Icons.close, color: Colors.grey),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Graph - Increased height for better Y-axis spacing
        Expanded(
          child: widget.isResultTile && widget.predicting
              ? Center(
                  child: widget.predictionContent ?? const SizedBox.shrink(),
                )
              : LineGraphWidget(
                  dataPoints: widget.dataPoints,
                  timestamps: widget.timestamps,
                  label: widget.label,
                  lineColor: widget.lineColor,
                  isExpanded: true,
                  minY: minY,
                  maxY: maxY,
                  yAxisFormatter: _formatYAxisValue,
                  yAxisDivisions: _getOptimalYAxisDivisions(),
                ),
        ),
        
        // Legend/Stats
        if (!widget.isResultTile && widget.dataPoints.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Min', widget.dataPoints.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)),
                _buildStat('Max', widget.dataPoints.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)),
                _buildStat('Avg', (widget.dataPoints.reduce((a, b) => a + b) / widget.dataPoints.length).toStringAsFixed(2)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactContent() {
    if (widget.isShrunken) {
      // Shrunken state - only heading for sensors, only icon for result
      return widget.isResultTile 
          ? _buildShrunkenResultContent()
          : _buildShrunkenSensorContent();
    }
    
    // Normal state
    return widget.isResultTile 
        ? _buildNormalResultContent()
        : _buildNormalSensorContent();
  }

  Widget _buildShrunkenResultContent() {
    if (widget.predicting) {
      return Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + 0.4 * _controller.value,
              child: widget.predictionContent ?? const Icon(Icons.water_drop, size: 40, color: aqua),
            );
          },
        ),
      );
    }
    
    if (widget.predictionResult == null) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getResultColor(),
          shape: BoxShape.circle,
        ),
        child: _buildIcon(20),
      ),
    );
  }

  Widget _buildShrunkenSensorContent() {
    // Get abbreviation and show value too
    final abbreviation = _getAbbreviation(widget.label);
    
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                abbreviation,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAbbreviation(String label) {
    switch (label) {
      case 'Dissolved Oxygen': return 'DO';
      case 'Temperature': return 'Temp';
      case 'Turbidity': return 'Turb';
      case 'TDS': return 'TDS';
      case 'pH': return 'pH';
      default: return label.substring(0, 3);
    }
  }

  Widget _buildNormalResultContent() {
    if (widget.predicting) {
      return widget.predictionContent ?? const SizedBox.shrink();
    }
    
    if (widget.predictionResult == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getResultColor(),
            shape: BoxShape.circle,
          ),
          child: _buildIcon(24),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.predictionResult!.startsWith("Prediction error") ? "Error" : widget.predictionResult!,
              style: TextStyle(
                color: _getResultTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Mini graph
        if (widget.dataPoints.isNotEmpty)
          Expanded(
            child: LineGraphWidget(
              dataPoints: widget.dataPoints,
              timestamps: widget.timestamps,
              label: widget.label,
              lineColor: widget.lineColor,
              isExpanded: false,
              minY: minY,
              maxY: maxY,
            ),
          ),
      ],
    );
  }

  Widget _buildNormalSensorContent() {
    return Column(
      children: [
        // Icon and value
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: aqua.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: _buildIcon(20)),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16, // Changed from 12 to 16
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.value,
                    style: const TextStyle(
                      fontSize: 20, // Changed from 16 to 20
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Mini graph
        if (widget.dataPoints.isNotEmpty)
          Expanded(
            flex: 2,
            child: LineGraphWidget(
              dataPoints: widget.dataPoints,
              timestamps: widget.timestamps,
              label: widget.label,
              lineColor: widget.lineColor,
              isExpanded: false,
              minY: minY,
              maxY: maxY,
            ),
          ),
      ],
    );
  }

  Widget _buildIcon(double size) {
    if (widget.isResultTile && widget.predictionResult != null) {
      final isError = widget.predictionResult!.toLowerCase().contains("error");
      final isPotable = widget.predictionResult == "Potable";
      
      String iconAsset;
      if (isError) {
        iconAsset = 'assets/danger.svg';
      } else if (isPotable) {
        iconAsset = 'assets/leaf.svg';
      } else {
        iconAsset = 'assets/block.svg';
      }
      
      return SvgPicture.asset(
        iconAsset,
        width: size,
        height: size,
        color: Colors.white,
      );
    }
    
    return SvgPicture.asset(
      widget.iconPath,
      width: size,
      height: size,
      color: aqua,
    );
  }

  Color _getResultColor() {
    if (widget.predictionResult == null) return Colors.grey.shade500;
    
    final isError = widget.predictionResult!.toLowerCase().contains("error");
    final isPotable = widget.predictionResult == "Potable";
    
    if (isError) return Colors.orange.shade500;
    if (isPotable) return Colors.green.shade500;
    return Colors.red.shade500;
  }

  Color _getResultTextColor() {
    if (widget.predictionResult == null) return Colors.grey.shade700;
    
    final isError = widget.predictionResult!.toLowerCase().contains("error");
    final isPotable = widget.predictionResult == "Potable";
    
    if (isError) return Colors.orange.shade700;
    if (isPotable) return Colors.green.shade700;
    return Colors.red.shade700;
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}