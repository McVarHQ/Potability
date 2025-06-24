import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';

import 'package:potability/widgets/log_tile.dart';
import 'package:potability/widgets/sensor_tile.dart';
import 'package:potability/widgets/loading_animation.dart';
import 'package:potability/widgets/sidebar.dart';

const String apiUrl = 'https://potability-production.up.railway.app/predict';
const String broker = 'a33cad5yg72pky-ats.iot.ap-southeast-2.amazonaws.com';
const String topic = 'esp32/pub';
const aqua = Color(0xFF00BCD4);

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
  }

  Future<void> connectToMQTT() async {
    client = MqttServerClient(broker, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client!
      ..port = 8883
      ..secure = true
      ..logging(on: false)
      ..onDisconnected = () {
        setState(() => awsConnected = false);
        debugPrint("🔌 Disconnected");
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
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
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
        setState(() => backendConnected = true);
      } else {
        throw Exception("Prediction failed");
      }
    } catch (e) {
      predictionResult = "Error";
      errorMessage = "Something went wrong.";
      logs.insert(0, {
        "timestamp": DateTime.now().toIso8601String(),
        "inputs": {},
        "result": "Prediction error: $e"
      });
      setState(() => backendConnected = false);
    }

    setState(() => predicting = false);
  }

  Widget buildResultTile() {
    if (predicting) {
      return Lottie.asset('assets/water.json', width: 140, height: 140);
    }

    if (predictionResult == null) return const SizedBox(height: 140, width: 140);

    String label = '';
    String icon = '';
    Color color;

    switch (predictionResult) {
      case "Potable":
        icon = 'leaf.png';
        label = 'Potable';
        color = Colors.green;
        break;
      case "Not Potable":
        icon = 'block.png';
        label = 'Not Potable';
        color = Colors.red;
        break;
      default:
        icon = 'danger.png';
        label = 'Error';
        color = Colors.yellow[800]!;
        break;
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/$icon', width: 40),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          if (label == "Error" && errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      SensorTile(label: "pH", value: sensorData["pH"].toString(), iconPath: 'assets/ph.png'),
      SensorTile(label: "TDS", value: sensorData["TDS"].toString(), iconPath: 'assets/tds.png'),
      SensorTile(label: "Turbidity", value: sensorData["Turbidity"].toString(), iconPath: 'assets/turbidity.png'),
      SensorTile(label: "Temperature", value: sensorData["Temperature"].toString(), iconPath: 'assets/temperature.png'),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(
        logs: logs,
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                SensorTile(
                  label: "Dissolved Oxygen",
                  value: sensorData["Dissolved Oxygen"].toString(),
                  iconPath: 'assets/do.png',
                  wide: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [tiles[0], const SizedBox(height: 8), tiles[1]],
                      ),
                    ),
                    const SizedBox(width: 12),
                    buildResultTile(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [tiles[2], const SizedBox(height: 8), tiles[3]],
                      ),
                    ),
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
              ],
            ),
          ),
          if (logs.isNotEmpty && !predicting)
            Positioned.fill(
              top: MediaQuery.of(context).size.height * 0.55,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                children: logs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final log = entry.value;

                  return LogTile(
                    log: log,
                    expanded: expandedIndex == index,
                    onTap: () {
                      setState(() {
                        expandedIndex = expandedIndex == index ? null : index;
                      });
                    },
                    onDelete: () {
                      setState(() {
                        logs.removeAt(index);
                        if (expandedIndex == index) expandedIndex = null;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
