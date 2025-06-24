import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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

class _LogTileState extends State<LogTile> {
  @override
  Widget build(BuildContext context) {
    final isPotable = widget.log["result"] == "Potable";
    final isError = widget.log["result"].toString().toLowerCase().contains("error");

    String iconAsset;
    Color backgroundColor;
    Color borderColor;
    String resultText;

    if (isError) {
      iconAsset = 'assets/danger.svg';
      backgroundColor = Colors.orange;
      borderColor = Colors.orange.shade300;
      resultText = "Error";
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
        ? DateFormat.yMMMd().add_jm().format(parsed)
        : timestamp.toString();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: backgroundColor,
                  radius: 16,
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Result: $resultText",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Time: $timeStr",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (widget.expanded) ...[
              const Divider(height: 16),
              ...widget.log["inputs"].entries.map<Widget>((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${_labelize(e.key)}:",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "${e.value}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, size: 20, color: aqua),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.log.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, size: 20, color: aqua),
                    onPressed: widget.onDelete,
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  /// Beautify labels for UI (e.g. totaldissolvedsolids → TDS)
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
        return key;
    }
  }
}
