import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:potability/widgets/log_tile.dart';

const String logsApiUrl = 'https://potability-production.up.railway.app/logs';

class DbLogsScreen extends StatefulWidget {
  const DbLogsScreen({super.key});

  @override
  State<DbLogsScreen> createState() => _DbLogsScreenState();
}

class _DbLogsScreenState extends State<DbLogsScreen> {
  List<Map<String, dynamic>> dbLogs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      final res = await http.get(Uri.parse(logsApiUrl));
      if (res.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(res.body);
        setState(() {
          dbLogs = jsonList.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        throw Exception('Failed to fetch logs');
      }
    } catch (e) {
      setState(() {
        dbLogs = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Database Logs")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dbLogs.isEmpty
              ? const Center(child: Text("No logs available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dbLogs.length,
                  itemBuilder: (context, index) {
                    return LogTile(
                      log: dbLogs[index],
                      expanded: false,
                      onTap: () => setState(() {
                        for (int i = 0; i < dbLogs.length; i++) {
                          if (i != index) dbLogs[i]['expanded'] = false;
                        }
                        dbLogs[index]['expanded'] = !(dbLogs[index]['expanded'] ?? false);
                      }),
                      onDelete: () {},
                    );
                  },
                ),
    );
  }
}
