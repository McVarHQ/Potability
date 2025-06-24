import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    Color tileColor;
    Color borderColor;
    IconData icon;
    String resultText;

    if (isError) {
      tileColor = Colors.yellow.shade100;
      borderColor = Colors.orange;
      icon = Icons.error_outline;
      resultText = "Error";
    } else if (isPotable) {
      tileColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      icon = Icons.check_circle;
      resultText = "Potable";
    } else {
      tileColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      icon = Icons.block;
      resultText = "Not Potable";
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: borderColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Result: $resultText",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Time: ${widget.log["timestamp"]}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (widget.expanded) ...[
              const Divider(height: 16),
              ...widget.log["inputs"].entries.map<Widget>((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text("${e.key}: ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text("${e.value}", style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.log.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
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
}
