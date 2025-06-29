import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

const aqua = Color(0xFF00BCD4);

class LogTile extends StatefulWidget {
  final Map<String, dynamic> log;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LogTile({
    super.key,
    required this.log,
    required this.expanded,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<LogTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(LogTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultRaw = widget.log["result"]?.toString() ?? "";
    final isError = resultRaw.toLowerCase().contains("error");
    final isPotable = resultRaw == "Potable";

    String iconAsset;
    Color backgroundColor;
    Color borderColor;
    String resultText;

    if (isError) {
      iconAsset = 'assets/danger.svg';
      backgroundColor = Colors.orange;
      borderColor = Colors.orange.shade300;
      resultText = resultRaw;
    } else if (isPotable) {
      iconAsset = 'assets/leaf.svg';
      backgroundColor = Colors.green;
      borderColor = Colors.green.shade300;
      resultText = "Potable";
    } else {
      iconAsset = 'assets/block.svg';
      backgroundColor = Colors.red;
      borderColor = Colors.red.shade300;
      resultText = "Not Potable";
    }

    final timestamp = widget.log["timestamp"];
    final parsed = DateTime.tryParse(timestamp ?? "")?.toLocal();
    final timeStr = parsed != null
        ? DateFormat.yMMMMd().add_jm().format(parsed)
        : (timestamp?.toString() ?? "Unknown time");

    final inputs = widget.log["inputs"];
    final isInputValid = inputs is Map<String, dynamic> && inputs.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              borderColor.withOpacity(0.1),
              borderColor.withOpacity(0.05),
              Colors.white.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: backgroundColor,
                  radius: 18,
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Result: $resultText",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Time: $timeStr",
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: widget.expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: backgroundColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: widget.expanded && isInputValid
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 24),
                        const Text(
                          "Inputs:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...inputs.entries.map<Widget>((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _labelize(entry.key),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "${entry.value}",
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Copy log details',
                              icon: const Icon(Icons.copy, size: 20, color: aqua),
                              onPressed: () {
                                const JsonEncoder encoder = JsonEncoder.withIndent('  ');
                                final String prettyJson = encoder.convert(widget.log);
                                Clipboard.setData(ClipboardData(text: prettyJson));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📋 Copied to clipboard')),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete this log',
                              icon: const Icon(Icons.delete_outline, size: 20, color: aqua),
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _labelize(String key) {
    switch (key.toLowerCase()) {
      case 'ph':
        return 'pH';
      case 'temperature':
        return 'Temperature';
      case 'turbidity':
        return 'Turbidity';
      case 'totaldissolvedsolids':
        return 'TDS';
      case 'dissolvedoxygen':
        return 'Dissolved Oxygen';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }
}