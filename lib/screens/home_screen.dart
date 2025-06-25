import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'package:potability/widgets/log_tile.dart';
import 'package:potability/widgets/sensor_tile.dart';
import 'package:potability/widgets/sidebar.dart';

const aqua = Color(0xFF00BCD4);
const String apiUrl = 'https://potability-production.up.railway.app/predict';
const String logsApiUrl = 'https://potability-production.up.railway.app/logs';
const String broker = 'a33cad5yg72pky-ats.iot.ap-southeast-2.amazonaws.com';
const String topic = 'esp32/pub';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, dynamic> sensorData = {
    'pH': '--',
    'TDS': '--',
    'Turbidity': '--',
    'Temperature': '--',
    'Dissolved Oxygen': '--',
  };

  final List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> filteredLogs = [];
  List<Map<String, dynamic>> postgresLogs = [];

  bool predicting = false;
  MqttServerClient? client;
  bool awsConnected = false;
  bool backendConnected = false;
  int? expandedIndex;

  String? predictionResult;
  String? errorMessage;

  List<Map<String, dynamic>> get sessionLogs => logs.where((log) {
    final time = DateTime.tryParse(log["timestamp"] ?? "");
    return time != null && time.isAfter(DateTime.now().subtract(const Duration(hours: 12)));
  }).toList();

  @override
  void initState() {
    super.initState();
    connectToMQTT();
    preloadLogsFromDB();
  }

  Future<void> preloadLogsFromDB() async {
    try {
      final res = await http.get(Uri.parse(logsApiUrl));
      if (res.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(res.body);
        setState(() {
          postgresLogs = jsonList.cast<Map<String, dynamic>>();
          backendConnected = true;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to preload logs: $e");
    }
  }

  Future<void> connectToMQTT() async {
    client = MqttServerClient(broker, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client!
      ..port = 8883
      ..secure = true
      ..logging(on: false)
      ..onDisconnected = () {
        setState(() => awsConnected = false);
        debugPrint("🔌 Disconnected from MQTT");
      };

    try {
      final tempDir = await getTemporaryDirectory();
      final caPath = '${tempDir.path}/CA.pem';
      final certPath = '${tempDir.path}/cert.pem';
      final keyPath = '${tempDir.path}/private.key';

      await File(caPath).writeAsBytes((await rootBundle.load('assets/aws/CA.pem')).buffer.asUint8List());
      await File(certPath).writeAsBytes((await rootBundle.load('assets/aws/cert.pem')).buffer.asUint8List());
      await File(keyPath).writeAsBytes((await rootBundle.load('assets/aws/private.key')).buffer.asUint8List());

      final context = SecurityContext.defaultContext;
      context.setTrustedCertificates(caPath);
      context.useCertificateChain(certPath);
      context.usePrivateKey(keyPath);
      client!.securityContext = context;

      await client!.connect();
      setState(() => awsConnected = true);
      debugPrint("✅ MQTT connected");

      client!.subscribe(topic, MqttQos.atMostOnce);
      client!.updates!.listen((c) {
        final msg = (c[0].payload as MqttPublishMessage).payload.message;
        final jsonStr = String.fromCharCodes(msg);
        debugPrint("📥 MQTT: $jsonStr");

        try {
          final parsed = json.decode(jsonStr);
          setState(() {
            sensorData['pH'] = parsed['ph'].toString();
            sensorData['TDS'] = parsed['totaldissolvedsolids'].toString();
            sensorData['Turbidity'] = parsed['turbidity'].toString();
            sensorData['Temperature'] = parsed['temperature'].toString();
            sensorData['Dissolved Oxygen'] = parsed['dissolvedoxygen'].toString();
          });
        } catch (e) {
          debugPrint("⚠️ MQTT parse error: $e");
        }
      });
    } catch (e) {
      debugPrint('❌ MQTT error: $e');
    }
  }

  Future<void> predict() async {
    setState(() {
      predicting = true;
      errorMessage = null;
    });

    try {
      final data = {
        "ph": double.tryParse(sensorData["pH"].toString()) ?? 0.0,
        "totaldissolvedsolids": double.tryParse(sensorData["TDS"].toString()) ?? 0.0,
        "turbidity": double.tryParse(sensorData["Turbidity"].toString()) ?? 0.0,
        "temperature": double.tryParse(sensorData["Temperature"].toString()) ?? 0.0,
        "dissolvedoxygen": double.tryParse(sensorData["Dissolved Oxygen"].toString()) ?? 0.0,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        logs.insert(0, result);
        filteredLogs = List.from(sessionLogs);
        setState(() => backendConnected = true);
      } else {
        throw Exception("Prediction failed");
      }
    } catch (e) {
      final fallback = {
        "timestamp": DateTime.now().toIso8601String(),
        "inputs": {},
        "result": "Prediction error: $e"
      };
      logs.insert(0, fallback);
      filteredLogs = List.from(sessionLogs);
      setState(() {
        backendConnected = false;
        errorMessage = "Something went wrong.";
      });
    }

    setState(() => predicting = false);
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final tiles = [
      SensorTile(label: "pH", value: sensorData["pH"].toString(), iconPath: 'assets/ph.svg'),
      SensorTile(label: "TDS", value: sensorData["TDS"].toString(), iconPath: 'assets/tds.svg'),
      SensorTile(label: "Turbidity", value: sensorData["Turbidity"].toString(), iconPath: 'assets/turbidity.svg'),
      SensorTile(label: "Temperature", value: sensorData["Temperature"].toString(), iconPath: 'assets/temperature.svg'),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(
        postgresLogs: postgresLogs,
        awsConnected: awsConnected,
        backendConnected: backendConnected,
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Water Potability'),
        backgroundColor: aqua,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SensorTile(
                      label: "Dissolved Oxygen",
                      value: sensorData["Dissolved Oxygen"].toString(),
                      iconPath: 'assets/do.svg',
                      wide: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Column(children: [tiles[0], const SizedBox(height: 8), tiles[1]])),
                        const SizedBox(width: 12),
                        buildResultTile(),
                        const SizedBox(width: 12),
                        Expanded(child: Column(children: [tiles[2], const SizedBox(height: 8), tiles[3]])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: predicting ? null : predict,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: predicting ? Colors.grey : aqua,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Predict", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sessionLogs.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: SvgPicture.asset('assets/clear.svg', width: 24, color: aqua),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Clear Logs?"),
                                  content: const Text("Are you sure you want to delete all logs?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          logs.removeWhere((log) => sessionLogs.contains(log));
                                          filteredLogs = List.from(sessionLogs);
                                          expandedIndex = null;
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Clear"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: SvgPicture.asset('assets/filter.svg', width: 24, color: aqua),
                            onPressed: showFilterDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: aqua),
                            onPressed: downloadLogsToUserLocation,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: aqua),
                            onPressed: shareLogsFile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final localTime = DateTime.tryParse(log["timestamp"] ?? "")?.toLocal().toString() ?? "";
                          log["timestamp"] = localTime;
                          return LogTile(
                            log: log,
                            expanded: expandedIndex == index,
                            onTap: () => setState(() {
                              expandedIndex = expandedIndex == index ? null : index;
                            }),
                            onDelete: () => setState(() {
                              final toDelete = filteredLogs[index];
                              logs.remove(toDelete);
                              filteredLogs.removeAt(index);
                              if (expandedIndex == index) expandedIndex = null;
                            }),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildResultTile() {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: predictionResult == null
              ? Colors.grey[200]
              : predictionResult == "Potable"
                  ? Colors.green[100]
                  : Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: predictionResult == null
            ? Center(child: Lottie.asset('assets/water.json', repeat: true))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    predictionResult!,
                    style: TextStyle(
                      color: predictionResult == "Potable" ? Colors.green : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                    )
                ],
              ),
      ),
    );
  }

  Future<void> downloadLogsToUserLocation() async {
    try {
      final directory = await getExternalStorageDirectory();
      final path = directory?.path ?? '/storage/emulated/0/Download';
      final file = File('$path/water_logs_${DateTime.now().millisecondsSinceEpoch}.json');

      final data = json.encode(sessionLogs);
      await file.writeAsString(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Logs saved to: ${file.path}")),
      );
    } catch (e) {
      debugPrint("❌ Download error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download logs")),
      );
    }
  }

  Future<void> shareLogsFile() async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/session_logs.json';
      final file = File(path);

      await file.writeAsString(json.encode(sessionLogs));
      await Share.shareXFiles([XFile(file.path)], text: 'Session Logs');

      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) file.deleteSync();
      });
    } catch (e) {
      debugPrint("❌ Share error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to share logs")),
      );
    }
  }

  void showFilterDialog() {
    // Add any filter dialog logic here if needed.
  }
}
