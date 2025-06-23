import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Sidebar extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const Sidebar({super.key, required this.logs});

  Future<void> downloadLogs(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/logs.txt');
      await file.writeAsString(jsonEncode(logs));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logs downloaded to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
        children: [
          const Text("Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Download Logs"),
            onTap: () {
              Navigator.pop(context);
              downloadLogs(context);
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("App Version 1.0"),
          ),
        ],
      ),
    );
  }
}
