import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:water_potability/widgets/log_tile.dart';
import 'package:water_potability/widgets/sensor_tile.dart';
import 'package:water_potability/widgets/loading_animation.dart';

const String apiUrl = 'https://potability-production.up.railway.app/predict';
const String broker = 'https://a4ldutufacmsk-ats.iot.ap-south-1.amazonaws.com/';
const String topic = 'esp32/pub';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    client = MqttServerClient(broker, 'flutter_client');
    client!.port = 8883;
    client!.secure = true;
    client!.logging(on: false);
    client!.onDisconnected = () => debugPrint("🔌 Disconnected");

    final context = SecurityContext.defaultContext;
    context.setTrustedCertificates('aws/CA.pem');
    context.useCertificateChain('aws/cert.pem');
    context.usePrivateKey('aws/private.key');

    client!.securityContext = context;

    try {
      await client!.connect();
      client!.subscribe(topic, MqttQos.atMostOnce);
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final msg = (c[0].payload as MqttPublishMessage).payload.message;
        final jsonStr = String.fromCharCodes(msg);
        try {
          final parsed = json.decode(jsonStr);
          setState(() {
            parsed.forEach((key, val) {
              String k = key.trim();
              if (sensorData.containsKey(k)) {
                sensorData[k] = val.toString();
              }
            });
          });
        } catch (_) {
          debugPrint("⚠️ MQTT JSON Parse failed");
        }
      });
    } catch (e) {
      debugPrint('❌ MQTT connect error: $e');
    }
  }

  Future<void> predict() async {
    setState(() => predicting = true);

    final data = {
      "pH": sensorData["pH"],
      "TDS": sensorData["TDS"],
      "Turbidity": sensorData["Turbidity"],
      "Temperature": sensorData["Temperature"],
      "Dissolved_Oxygen": sensorData["Dissolved_Oxygen"]
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

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

    setState(() => predicting = false);
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = logs.isNotEmpty && logs[0]["result"] == "Potable"
        ? Colors.green
        : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Potability'),
        backgroundColor: Colors.cyan.shade600,
      ),
      body: predicting
          ? const LoadingAnimation()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: sensorData.entries.map((entry) {
                      return SensorTile(
                        label: entry.key,
                        value: entry.value.toString(),
                        iconPath: 'assets/${entry.key.toLowerCase().replaceAll(" ", "_")}.png',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logs.isEmpty
                          ? Colors.cyan
                          : (logs[0]["result"] == "Potable"
                              ? Colors.green
                              : Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: predict,
                    child: const Text("Predict"),
                  ),
                  const SizedBox(height: 8),
                  if (logs.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => logs.clear());
                      },
                      child: const Text("Clear Logs"),
                    ),
                  const SizedBox(height: 8),
                  ...logs.map((log) => LogTile(log: log)).toList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
