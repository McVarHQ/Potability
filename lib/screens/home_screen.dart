import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:potability/widgets/loading_animation.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _backgroundController;
  
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
    
    // Initialize background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    connectToMQTT();
    preloadLogsFromDB();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
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
        setState(() {
          backendConnected = true;
          predictionResult = result["result"]?.toString();
        });
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
      body: Stack(
        children: [
          // Enhanced background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFE0F7FA),
                      const Color(0xFFF0F9FF),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Floating orbs
                    Positioned(
                      top: -100 + (_backgroundController.value * 50),
                      right: -100 + (_backgroundController.value * 30),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              aqua.withOpacity(0.1),
                              aqua.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150 + (_backgroundController.value * -40),
                      left: -100 + (_backgroundController.value * 20),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF0891B2).withOpacity(0.1),
                              const Color(0xFF0891B2).withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Main content
          Column(
            children: [
              // Enhanced App Bar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [aqua, const Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: aqua.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Water Potability',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Dissolved Oxygen - Wide tile
                      SensorTile(
                        label: "Dissolved Oxygen",
                        value: sensorData["Dissolved Oxygen"].toString(),
                        iconPath: 'assets/do.svg',
                        wide: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // Main sensor grid with prediction tile
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column
                          Expanded(
                            child: Column(
                              children: [
                                tiles[0], // pH
                                const SizedBox(height: 12),
                                tiles[1], // TDS
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Center prediction tile
                          Expanded(child: buildResultTile()),
                          const SizedBox(width: 12),
                          
                          // Right column
                          Expanded(
                            child: Column(
                              children: [
                                tiles[2], // Turbidity
                                const SizedBox(height: 12),
                                tiles[3], // Temperature
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Enhanced Predict Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: predicting ? null : predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: predicting ? Colors.grey : aqua,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: aqua.withOpacity(0.4),
                          ),
                          child: Text(
                            predicting ? "Predicting..." : "Predict",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Session Logs
                      if (sessionLogs.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Session Logs",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResultTile() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: predicting 
            ? null  // No background during prediction
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: predictionResult == null
                    ? [Colors.white, Colors.grey.shade100]
                    : predictionResult == "Potable"
                        ? [Colors.green.shade100, Colors.green.shade50]
                        : [Colors.red.shade100, Colors.red.shade50],
              ),
        borderRadius: BorderRadius.circular(16),
        border: predicting 
            ? null  // No border during prediction
            : Border.all(
                color: predictionResult == null
                    ? Colors.grey.shade200
                    : predictionResult == "Potable"
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                width: 1.5,
              ),
        boxShadow: predicting 
            ? null  // No shadow during prediction
            : [
                BoxShadow(
                  color: (predictionResult == null ? Colors.grey : predictionResult == "Potable" ? Colors.green : Colors.red).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: predicting
          ? Center(child: LoadingAnimation(predicting: predicting))
          : predictionResult == null
              ? const SizedBox.shrink()  // Empty space instead of "Ready to predict"
              : Center(  // Center the entire result content
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: predictionResult == "Potable" ? Colors.green.shade500 : Colors.red.shade500,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          predictionResult == "Potable" ? 'assets/leaf.svg' : 'assets/block.svg',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        predictionResult!,
                        style: TextStyle(
                          color: predictionResult == "Potable" ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            errorMessage!, 
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        )
                    ],
                  ),
                ),
    );
  }

  Future<void> downloadLogsToUserLocation() async {
    try {
      final data = json.encode(sessionLogs);
      
      // For Android 11+ compatibility, save to app's documents directory first
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'session_logs_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      // Write the file
      await file.writeAsString(data);
      
      // Share the file instead of using file picker (more reliable)
      await Share.shareXFiles([XFile(file.path)], text: 'Session Logs');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Logs saved and shared: $fileName")),
      );
      
      // Clean up the temp file after a delay
      Future.delayed(const Duration(seconds: 10), () {
        if (file.existsSync()) file.deleteSync();
      });
      
    } catch (e) {
      debugPrint("❌ Download error: $e");
      
      // Fallback: Try the old method
      try {
        final data = json.encode(sessionLogs);
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Session Logs',
          fileName: 'session_logs.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(data), // Provide bytes directly
        );

        if (path != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Logs saved to: $path")),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Save cancelled")),
          );
        }
      } catch (fallbackError) {
        debugPrint("❌ Fallback download error: $fallbackError");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to download logs. Try sharing instead.")),
        );
      }
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