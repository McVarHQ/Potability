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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandableTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShrunken != oldWidget.isShrunken) {
      if (widget.isShrunken) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
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
            ),
          ),
        );
      },
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: widget.lineColor.withOpacity(0.3),
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
        
        // Graph
        Expanded(
          child: widget.isResultTile && widget.predicting
              ? widget.predictionContent ?? const SizedBox.shrink()
              : LineGraphWidget(
                  dataPoints: widget.dataPoints,
                  timestamps: widget.timestamps,
                  label: widget.label,
                  lineColor: widget.lineColor,
                  isExpanded: true,
                  minY: minY,
                  maxY: maxY,
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
      return widget.predictionContent ?? const SizedBox.shrink();
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
    return Center(
      child: Text(
        widget.label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
        Text(
          widget.predictionResult!.startsWith("Prediction error") ? "Error" : widget.predictionResult!,
          style: TextStyle(
            color: _getResultTextColor(),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
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
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
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