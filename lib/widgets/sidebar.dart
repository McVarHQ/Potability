import 'package:flutter/material.dart';
import 'package:potability/widgets/log_tile.dart';
import 'dart:convert';
import 'dart:io';

class Sidebar extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const Sidebar({super.key, required this.logs});

  void _downloadLogs(BuildContext context) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(logs);
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/potability_logs.json');
    await file.writeAsString(jsonStr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📁 Logs saved to ${file.path}')),
    );

    // TODO: Add sharing or opening logic if needed
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Potability Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text("No logs yet."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return LogTile(log: logs[index]);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => _downloadLogs(context),
                icon: const Icon(Icons.download),
                label: const Text("Download Logs"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
