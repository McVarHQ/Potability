import 'dart:convert';
import 'dart:io';
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
import 'package:potability/widgets/expandable_tile.dart';
import 'package:potability/widgets/sidebar.dart';

const aqua = Color(0xFF00BCD4);
const String apiUrl = 'https://water-potability.mcblcvr.workers.dev/predict';
const String logsApiUrl = 'https://water-potability.mcblcvr.workers.dev/logs';
const String broker = 'a33cad5yg72pky-ats.iot.ap-southeast-2.amazonaws.com';
const String topic = 'esp32/pub';

class SensorData {
  final double value;
  final DateTime timestamp;
  
  SensorData({required this.value, required this.timestamp});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Current sensor values
  final Map<String, dynamic> sensorData = {
    'pH': '--',
    'TDS': '--',
    'Turbidity': '--',
    'Temperature': '--',
    'Dissolved Oxygen': '--',
  };

  // Historical sensor data for graphs
  final Map<String, List<SensorData>> sensorHistory = {
    'pH': [],
    'TDS': [],
    'Turbidity': [],
    'Temperature': [],
    'Dissolved Oxygen': [],
    'Result': [], // For prediction results (1 = Potable, 0 = Not Potable)
  };

  final List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> filteredLogs = [];
  List<Map<String, dynamic>> postgresLogs = [];

  bool predicting = false;
  MqttServerClient? client;
  bool awsConnected = false;
  bool backendConnected = false;
  int? expandedIndex;
  String? expandedTileId;

  String? predictionResult;
  String? errorMessage;

  List<Map<String, dynamic>> get sessionLogs => logs.where((log) {
    final time = DateTime.tryParse(log["timestamp"] ?? "");
    return time != null && time.isAfter(DateTime.now().subtract(const Duration(hours: 12)));
  }).toList();

  @override
  void initState() {
    super.initState();
    
    // Initialize filteredLogs
    filteredLogs = List.from(sessionLogs);
    
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

  void _addSensorDataPoint(String sensor, double value) {
    setState(() {
      final now = DateTime.now();
      sensorHistory[sensor]?.add(SensorData(value: value, timestamp: now));
      
      // Keep only last 50 data points for performance
      if (sensorHistory[sensor]!.length > 50) {
        sensorHistory[sensor]!.removeAt(0);
      }
    });
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
            
            // Add to history for graphs
            _addSensorDataPoint('pH', parsed['ph']?.toDouble() ?? 0.0);
            _addSensorDataPoint('TDS', parsed['totaldissolvedsolids']?.toDouble() ?? 0.0);
            _addSensorDataPoint('Turbidity', parsed['turbidity']?.toDouble() ?? 0.0);
            _addSensorDataPoint('Temperature', parsed['temperature']?.toDouble() ?? 0.0);
            _addSensorDataPoint('Dissolved Oxygen', parsed['dissolvedoxygen']?.toDouble() ?? 0.0);
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
          
          // Add result to history (1 for Potable, 0 for Not Potable)
          final resultValue = predictionResult == "Potable" ? 1.0 : 0.0;
          _addSensorDataPoint('Result', resultValue);
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
        predictionResult = "Prediction error: $e";
        errorMessage = "Something went wrong.";
        
        // Add error result to history
        _addSensorDataPoint('Result', -0.1); // Special value for errors
      });
    }

    setState(() => predicting = false);
  }

  void _toggleTileExpansion(String tileId) {
    setState(() {
      if (expandedTileId == tileId) {
        expandedTileId = null; // Collapse if already expanded
      } else {
        expandedTileId = tileId; // Expand new tile
      }
    });
  }

  List<double> _getDataPoints(String sensor) {
    return sensorHistory[sensor]?.map((data) => data.value).toList() ?? [];
  }

  List<DateTime> _getTimestamps(String sensor) {
    return sensorHistory[sensor]?.map((data) => data.timestamp).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isAnyExpanded = expandedTileId != null;

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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE0F7FA),
                  Color(0xFFF0F9FF),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Floating orbs
                Positioned(
                  top: -100,
                  right: -100,
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
              ],
            ),
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
                      // University Logo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/uni_logo_full.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Expandable tiles grid
                      if (isAnyExpanded) 
                        _buildExpandedLayout()
                      else 
                        _buildNormalLayout(),
                      
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
                        // Action icons only - evenly spaced
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        const SizedBox(height: 16),
                        
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

  Widget _buildNormalLayout() {
    return Column(
      children: [
        // Dissolved Oxygen - Wide tile
        ExpandableTile(
          label: "Dissolved Oxygen",
          value: sensorData["Dissolved Oxygen"].toString(),
          iconPath: 'assets/do.svg',
          isExpanded: false,
          isShrunken: false,
          onTap: () => _toggleTileExpansion('dissolved_oxygen'),
          dataPoints: _getDataPoints('Dissolved Oxygen'),
          timestamps: _getTimestamps('Dissolved Oxygen'),
          lineColor: const Color(0xFF06B6D4),
        ),
        const SizedBox(height: 16),
        
        // Main sensor grid with prediction tile
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: [
                  ExpandableTile(
                    label: "pH",
                    value: sensorData["pH"].toString(),
                    iconPath: 'assets/ph.svg',
                    isExpanded: false,
                    isShrunken: false,
                    onTap: () => _toggleTileExpansion('ph'),
                    dataPoints: _getDataPoints('pH'),
                    timestamps: _getTimestamps('pH'),
                    lineColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  ExpandableTile(
                    label: "TDS",
                    value: sensorData["TDS"].toString(),
                    iconPath: 'assets/tds.svg',
                    isExpanded: false,
                    isShrunken: false,
                    onTap: () => _toggleTileExpansion('tds'),
                    dataPoints: _getDataPoints('TDS'),
                    timestamps: _getTimestamps('TDS'),
                    lineColor: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Center prediction tile - show empty space if no prediction
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (predictionResult != null || predicting)
                    ExpandableTile(
                      label: "Result",
                      value: predictionResult ?? "--",
                      iconPath: 'assets/leaf.svg',
                      isExpanded: false,
                      isShrunken: false,
                      onTap: () => _toggleTileExpansion('result'),
                      dataPoints: _getDataPoints('Result'),
                      timestamps: _getTimestamps('Result'),
                      lineColor: Colors.green,
                      isResultTile: true,
                      predictionResult: predictionResult,
                      predicting: predicting,
                      predictionContent: predicting ? LoadingAnimation(predicting: predicting) : null,
                    )
                  else
                    const SizedBox(height: 180), // Empty space placeholder
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Right column
            Expanded(
              child: Column(
                children: [
                  ExpandableTile(
                    label: "Turbidity",
                    value: sensorData["Turbidity"].toString(),
                    iconPath: 'assets/turbidity.svg',
                    isExpanded: false,
                    isShrunken: false,
                    onTap: () => _toggleTileExpansion('turbidity'),
                    dataPoints: _getDataPoints('Turbidity'),
                    timestamps: _getTimestamps('Turbidity'),
                    lineColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  ExpandableTile(
                    label: "Temperature",
                    value: sensorData["Temperature"].toString(),
                    iconPath: 'assets/temperature.svg',
                    isExpanded: false,
                    isShrunken: false,
                    onTap: () => _toggleTileExpansion('temperature'),
                    dataPoints: _getDataPoints('Temperature'),
                    timestamps: _getTimestamps('Temperature'),
                    lineColor: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedLayout() {
    return Column(
      children: [
        // Expanded tile
        if (expandedTileId != null)
          ExpandableTile(
            label: _getTileLabel(expandedTileId!),
            value: _getTileValue(expandedTileId!),
            iconPath: _getTileIcon(expandedTileId!),
            isExpanded: true,
            isShrunken: false,
            onTap: () => _toggleTileExpansion(expandedTileId!),
            dataPoints: _getDataPoints(_getTileDataKey(expandedTileId!)),
            timestamps: _getTimestamps(_getTileDataKey(expandedTileId!)),
            lineColor: _getTileColor(expandedTileId!),
            isResultTile: expandedTileId == 'result',
            predictionResult: expandedTileId == 'result' ? predictionResult : null,
            predicting: expandedTileId == 'result' ? predicting : false,
            predictionContent: expandedTileId == 'result' && predicting ? LoadingAnimation(predicting: predicting) : null,
          ),
        
        const SizedBox(height: 16),
        
        // Shrunken tiles - arranged in rows
        _buildShrunkenTilesGrid(),
      ],
    );
  }

  Widget _buildShrunkenTilesGrid() {
    final tiles = <Widget>[];
    
    // Add non-expanded tiles
    if (expandedTileId != 'dissolved_oxygen') {
      tiles.add(_buildShrunkenTile('dissolved_oxygen', 'DO', sensorData["Dissolved Oxygen"].toString()));
    }
    if (expandedTileId != 'ph') {
      tiles.add(_buildShrunkenTile('ph', 'pH', sensorData["pH"].toString()));
    }
    if (expandedTileId != 'tds') {
      tiles.add(_buildShrunkenTile('tds', 'TDS', sensorData["TDS"].toString()));
    }
    if (expandedTileId != 'turbidity') {
      tiles.add(_buildShrunkenTile('turbidity', 'Turb', sensorData["Turbidity"].toString()));
    }
    if (expandedTileId != 'temperature') {
      tiles.add(_buildShrunkenTile('temperature', 'Temp', sensorData["Temperature"].toString()));
    }
    if (expandedTileId != 'result' && predictionResult != null) {
      tiles.add(_buildShrunkenResultTile());
    }

    // Simple layout based on count
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: tiles,
    );
  }

  Widget _buildShrunkenTile(String tileId, String abbreviation, String value) {
    return SizedBox(
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => _toggleTileExpansion(tileId),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFE0F7FA).withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: aqua.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: aqua.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      abbreviation,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShrunkenResultTile() {
    if (predictionResult == null) return const SizedBox.shrink();
    
    final isError = predictionResult!.toLowerCase().contains("error");
    final isPotable = predictionResult == "Potable";
    
    Color bgColor;
    String iconAsset;
    
    if (isError) {
      bgColor = Colors.orange.shade100;
      iconAsset = 'assets/danger.svg';
    } else if (isPotable) {
      bgColor = Colors.green.shade100;
      iconAsset = 'assets/leaf.svg';
    } else {
      bgColor = Colors.red.shade100;
      iconAsset = 'assets/block.svg';
    }
    
    return SizedBox(
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => _toggleTileExpansion('result'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, bgColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isError 
                  ? Colors.orange.shade200 
                  : isPotable 
                      ? Colors.green.shade200 
                      : Colors.red.shade200, 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.orange : isPotable ? Colors.green : Colors.red).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError 
                    ? Colors.orange.shade500 
                    : isPotable 
                        ? Colors.green.shade500 
                        : Colors.red.shade500,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTileLabel(String tileId) {
    switch (tileId) {
      case 'dissolved_oxygen': return 'Dissolved Oxygen';
      case 'ph': return 'pH';
      case 'tds': return 'TDS';
      case 'result': return 'Result';
      case 'turbidity': return 'Turbidity';
      case 'temperature': return 'Temperature';
      default: return '';
    }
  }

  String _getTileValue(String tileId) {
    switch (tileId) {
      case 'dissolved_oxygen': return sensorData["Dissolved Oxygen"].toString();
      case 'ph': return sensorData["pH"].toString();
      case 'tds': return sensorData["TDS"].toString();
      case 'result': return predictionResult ?? "--";
      case 'turbidity': return sensorData["Turbidity"].toString();
      case 'temperature': return sensorData["Temperature"].toString();
      default: return '';
    }
  }

  String _getTileIcon(String tileId) {
    switch (tileId) {
      case 'dissolved_oxygen': return 'assets/do.svg';
      case 'ph': return 'assets/ph.svg';
      case 'tds': return 'assets/tds.svg';
      case 'result': return 'assets/leaf.svg';
      case 'turbidity': return 'assets/turbidity.svg';
      case 'temperature': return 'assets/temperature.svg';
      default: return 'assets/do.svg';
    }
  }

  String _getTileDataKey(String tileId) {
    switch (tileId) {
      case 'dissolved_oxygen': return 'Dissolved Oxygen';
      case 'ph': return 'pH';
      case 'tds': return 'TDS';
      case 'result': return 'Result';
      case 'turbidity': return 'Turbidity';
      case 'temperature': return 'Temperature';
      default: return '';
    }
  }

  Color _getTileColor(String tileId) {
    switch (tileId) {
      case 'dissolved_oxygen': return const Color(0xFF06B6D4);
      case 'ph': return const Color(0xFF3B82F6);
      case 'tds': return const Color(0xFF8B5CF6);
      case 'result': return Colors.green;
      case 'turbidity': return const Color(0xFFF59E0B);
      case 'temperature': return const Color(0xFFEF4444);
      default: return aqua;
    }
  }

  Future<void> downloadLogsToUserLocation() async {
    try {
      final data = json.encode(sessionLogs);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Session Logs',
        fileName: 'session_logs.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(data),
      );

      if (path != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Logs downloaded to: ${path.split('/').last}")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Download cancelled")),
        );
      }
    } catch (e) {
      debugPrint("❌ Download error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to download logs. Please check permissions.")),
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

      // Clean up the temp file after sharing
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) file.deleteSync();
      });
    } catch (e) {
      debugPrint("❌ Share error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to share logs")),
      );
    }
  }

  void showFilterDialog() {
    // Add any filter dialog logic here if needed.
  }
}