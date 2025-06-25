import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:potability/screens/db_logs_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

const aqua = Color(0xFF00BCD4);

class Sidebar extends StatefulWidget {
  final List<Map<String, dynamic>> postgresLogs;
  final bool backendConnected;
  final bool awsConnected;

  const Sidebar({
    super.key,
    required this.postgresLogs,
    required this.backendConnected,
    required this.awsConnected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  Map<String, List<String>> menuExtras = {};

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
          menuExtras = decoded.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          );
        });
      }
    } catch (e) {
      debugPrint("⚠️ menu.json not loaded or invalid: $e");
    }
  }

  Future<void> _downloadLogs(BuildContext context) async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(widget.postgresLogs);
      final output = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Logs As',
        fileName: 'potability_logs.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (output != null) {
        final file = File(output);
        await file.writeAsString(jsonStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📁 Logs saved:\n${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save logs: $e')),
      );
    }
  }

  Future<void> _shareLogs(BuildContext context) async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(widget.postgresLogs);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/potability_logs.json');
      await tempFile.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: '📊 Water Potability Logs',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to share logs: $e')),
      );
    }
  }

  void _viewLogs(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DbLogsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: aqua,
      child: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(iconTheme: const IconThemeData(color: Colors.white)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Logs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text("View Logs", style: TextStyle(color: Colors.white)),
                onTap: () => _viewLogs(context),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text("Download Logs", style: TextStyle(color: Colors.white)),
                onTap: () => _downloadLogs(context),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("Share Logs", style: TextStyle(color: Colors.white)),
                onTap: () => _shareLogs(context),
              ),
              const SizedBox(height: 24),
              const Text("Connections", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _buildBullet("AWS", widget.awsConnected),
              const SizedBox(height: 6),
              _buildBullet("Predictor", widget.backendConnected),
              const SizedBox(height: 24),
              if (menuExtras.isNotEmpty)
                ...menuExtras.entries.map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        ...entry.value.map((line) => Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text("• $line", style: const TextStyle(color: Colors.white70)),
                            )),
                        const SizedBox(height: 16),
                      ],
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String label, bool connected) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: connected ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: connected ? Colors.green.shade100 : Colors.red.shade100,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
