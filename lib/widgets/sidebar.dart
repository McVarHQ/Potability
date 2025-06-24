import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:potability/screens/db_logs_screen.dart';

const aqua = Color(0xFF00BCD4);

class Sidebar extends StatefulWidget {
  final List<Map<String, dynamic>> logs;
  final bool backendConnected;
  final bool awsConnected;

  const Sidebar({
    super.key,
    required this.logs,
    required this.backendConnected,
    required this.awsConnected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  Map<String, List<String>> menuExtras = {};
  File? logFile;

  @override
  void initState() {
    super.initState();
    _loadMenuExtras();
  }

  Future<void> _loadMenuExtras() async {
    try {
      final raw = await rootBundle.loadString('assets/menu.json');
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        setState(() {
          menuExtras = decoded.map((key, value) =>
              MapEntry(key, List<String>.from(value as List)));
        });
      }
    } catch (e) {
      debugPrint("⚠️ menu.json not loaded or invalid: $e");
    }
  }

  Future<void> _downloadLogs(BuildContext context) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(widget.logs);
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/potability_logs.json');
    await file.writeAsString(jsonStr);
    setState(() => logFile = file);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📁 Logs saved to ${file.path}')),
    );
  }

  Future<void> _shareLogs(BuildContext context) async {
    if (logFile != null && await logFile!.exists()) {
      await Share.shareXFiles(
        [XFile(logFile!.path)],
        text: '📊 Water Potability Logs',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please download logs first')),
      );
    }
  }

  void _viewLogs(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DbLogsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Logs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("View Logs"),
              onTap: () => _viewLogs(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Download Logs"),
              onTap: () => _downloadLogs(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text("Share Logs"),
              onTap: () => _shareLogs(context),
            ),
            const SizedBox(height: 24),
            const Text(
              "Connections",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBullet("AWS", widget.awsConnected),
            const SizedBox(height: 6),
            _buildBullet("Backend", widget.backendConnected),
            const SizedBox(height: 24),
            if (menuExtras.isNotEmpty)
              ...menuExtras.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...entry.value.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text("• $line"),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String label, bool connected) {
    return Row(
      children: [
        Icon(Icons.circle,
            size: 10, color: connected ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: connected ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}
