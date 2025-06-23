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

    final color =
        widget.log["result"] == "Potable" ? Colors.green[100] : Colors.red[100];

    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Result: ${widget.log["result"]}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Time: ${widget.log["timestamp"]}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (expanded) ...[
              const SizedBox(height: 6),
              ...widget.log["inputs"].entries.map<Widget>((e) {
                return Text("${e.key}: ${e.value}");
              }).toList(),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.log.toString()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => setState(() => deleted = true),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
