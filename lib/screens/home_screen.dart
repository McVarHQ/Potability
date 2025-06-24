import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:potability/widgets/log_tile.dart';
import 'package:potability/widgets/sensor_tile.dart';
import 'package:potability/widgets/loading_animation.dart';
import 'package:potability/widgets/sidebar.dart';

const String apiUrl = 'https://potability-production.up.railway.app/predict';
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
    'Dissolved_Oxygen': '--',
  };

  final List<Map<String, dynamic>> logs = [];
  bool predicting = false;
  MqttServerClient? client;

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
      ..logging(on: true)
      ..onDisconnected = () => debugPrint("🔌 Disconnected");

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
      debugPrint("✅ MQTT connected");

      client!.subscribe(topic, MqttQos.atMostOnce);
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final msg = (c[0].payload as MqttPublishMessage).payload.message;
        final jsonStr = String.fromCharCodes(msg);
        debugPrint("📥 MQTT message received: $jsonStr");

        try {
          final parsed = json.decode(jsonStr);
          setState(() {
            sensorData['pH'] = parsed['ph'].toString();
            sensorData['TDS'] = parsed['totaldissolvedsolids'].toString();
            sensorData['Turbidity'] = parsed['turbidity'].toString();
            sensorData['Temperature'] = parsed['temperature'].toString();
            sensorData['Dissolved_Oxygen'] = parsed['dissolvedoxygen'].toString();
          });
        } catch (e) {
          debugPrint("⚠️ Failed to parse MQTT payload: $e");
        }
      });
    } catch (e) {
      debugPrint('❌ MQTT connect error: $e');
    }
  }

  Future<void> predict() async {
    setState(() => predicting = true);

    try {
      final data = {
        "ph": double.tryParse(sensorData["pH"].toString()) ?? 0.0,
        "totaldissolvedsolids": double.tryParse(sensorData["TDS"].toString()) ?? 0.0,
        "turbidity": double.tryParse(sensorData["Turbidity"].toString()) ?? 0.0,
        "temperature": double.tryParse(sensorData["Temperature"].toString()) ?? 0.0,
        "dissolvedoxygen": double.tryParse(sensorData["Dissolved_Oxygen"].toString()) ?? 0.0,
      };

      debugPrint("📤 Sending to API: $data");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      debugPrint("🔁 API response: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        logs.insert(0, result);
      } else {
        logs.insert(0, {
          "timestamp": DateTime.now().toIso8601String(),
          "inputs": data,
          "result": "Prediction failed"
        });
      }
    } catch (e) {
      logs.insert(0, {
        "timestamp": DateTime.now().toIso8601String(),
        "inputs": {},
        "result": "Prediction error: $e"
      });
      debugPrint("❌ Prediction exception: $e");
    }

    setState(() => predicting = false);
  }


  @override
  Widget build(BuildContext context) {
    final resultColor = logs.isNotEmpty && logs[0]["result"] == "Potable"
        ? Colors.green
        : Colors.red;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(logs: logs),
      appBar: AppBar(
        title: const Text('Water Potability'),
        backgroundColor: Colors.cyan.shade600,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: predicting
          ? const LoadingAnimation()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: sensorData.entries.map((entry) {
                      return SensorTile(
                        label: entry.key,
                        value: entry.value.toString(),
                        iconPath:
                            'assets/${entry.key.toLowerCase().replaceAll(" ", "_")}.png',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.water_drop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logs.isEmpty
                          ? Colors.cyan
                          : (logs[0]["result"] == "Potable"
                              ? Colors.green
                              : Colors.red),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: predict,
                    label: const Text("Predict Water Quality"),
                  ),
                  const SizedBox(height: 12),
                  if (logs.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => logs.clear());
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text("Clear Logs"),
                    ),
                  const SizedBox(height: 8),
                  ...logs.map((log) => LogTile(log: log)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
