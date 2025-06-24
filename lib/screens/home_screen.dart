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

  List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> postgresLogs = []; // Add this to hold logs fetched at startup
  List<Map<String, dynamic>> filteredLogs = [];

  bool predicting = false;
  MqttServerClient? client;
  bool awsConnected = false;
  bool backendConnected = false;
  int? expandedIndex;

  String? predictionResult;
  String? errorMessage;

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
          logs = jsonList.cast<Map<String, dynamic>>();
          filteredLogs = List.from(logs);
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
        predictionResult = result["result"];
        logs.insert(0, result);
        filteredLogs = List.from(logs);
        setState(() => backendConnected = true);
      } else {
        throw Exception("Prediction failed");
      }
    } catch (e) {
      predictionResult = "Error";
      errorMessage = "Something went wrong.";
      final fallback = {
        "timestamp": DateTime.now().toIso8601String(),
        "inputs": {},
        "result": "Prediction error: $e"
      };
      logs.insert(0, fallback);
      filteredLogs = List.from(logs);
      setState(() => backendConnected = false);
    }

    setState(() => predicting = false);
  }

  Widget buildResultTile() {
    if (predicting) {
      return SizedBox(
        width: 140,
        height: 140,
        child: Lottie.asset('assets/water.json'),
      );
    }

    if (predictionResult == null) {
      return const SizedBox(height: 140, width: 140);
    }

    String label = '';
    String icon = '';
    Color color;

    switch (predictionResult) {
      case "Potable":
        icon = 'leaf.svg';
        label = 'Potable';
        color = Colors.green;
        break;
      case "Not Potable":
        icon = 'block.svg';
        label = 'Not Potable';
        color = Colors.red;
        break;
      default:
        icon = 'danger.svg';
        label = 'Error';
        color = Colors.orange;
        break;
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      height: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/$icon', width: 48, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            if (label == "Error" && errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text("Show All"),
            onTap: () {
              setState(() => filteredLogs = List.from(logs));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text("Only Potable"),
            onTap: () {
              setState(() => filteredLogs = logs
                  .where((log) => log['result'] == 'Potable')
                  .toList());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text("Only Not Potable"),
            onTap: () {
              setState(() => filteredLogs = logs
                  .where((log) => log['result'] == 'Not Potable')
                  .toList());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text("Only Errors"),
            onTap: () {
              setState(() => filteredLogs = logs
                  .where((log) => log['result'].toString().toLowerCase().contains("error"))
                  .toList());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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
                    if (logs.isNotEmpty) ...[
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
                                          logs.clear();
                                          filteredLogs.clear();
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
}
