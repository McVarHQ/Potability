import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogTile extends StatefulWidget {
  final Map<String, dynamic> log;

  const LogTile({super.key, required this.log});

  @override
  State<LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<LogTile> {
  bool expanded = false;
  bool deleted = false;

  @override
  Widget build(BuildContext context) {
    if (deleted) return const SizedBox.shrink();

    final isPotable = widget.log["result"] == "Potable";
    final tileColor = isPotable ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor = isPotable ? Colors.green.shade300 : Colors.red.shade300;
    final icon = isPotable ? Icons.check_circle : Icons.warning_amber;

    return AnimatedOpacity(
      opacity: deleted ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
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
                    "Result: ${widget.log["result"]}",
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
            if (expanded) ...[
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
                    onPressed: () => setState(() => deleted = true),
                  ),
                ],
              )
            ],
            GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  expanded ? "Hide details ▲" : "Show details ▼",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
