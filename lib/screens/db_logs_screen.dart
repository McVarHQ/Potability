import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:potability/widgets/log_tile.dart';
import 'package:intl/intl.dart';

const String logsApiUrl = 'https://potability-production.up.railway.app/logs';
const aqua = Color(0xFF00BCD4);

class DbLogsScreen extends StatefulWidget {
  const DbLogsScreen({super.key});

  @override
  State<DbLogsScreen> createState() => _DbLogsScreenState();
}

class _DbLogsScreenState extends State<DbLogsScreen> {
  List<Map<String, dynamic>> dbLogs = [];
  int? expandedIndex;
  bool loading = true;
  String? error;

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
        error = '❌ Error loading logs.';
        dbLogs = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Logs"),
        backgroundColor: aqua,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : dbLogs.isEmpty
                  ? const Center(child: Text("No logs available."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: dbLogs.length,
                      itemBuilder: (context, index) {
                        final log = dbLogs[index];
                        final rawTimestamp = log["timestamp"];
                        final parsedTime = DateTime.tryParse(rawTimestamp ?? "");
                        final formatted = parsedTime != null
                            ? DateFormat.yMMMd().add_jm().format(parsedTime.toLocal())
                            : rawTimestamp.toString();
                        log["timestamp"] = formatted;

                        return LogTile(
                          log: log,
                          expanded: expandedIndex == index,
                          onTap: () => setState(() {
                            expandedIndex = expandedIndex == index ? null : index;
                          }),
                          onDelete: () {
                            // Deletion from DB not allowed here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cannot delete logs from database view.")),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}