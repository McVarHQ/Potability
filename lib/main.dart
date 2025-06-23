import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:water_potability/screens/splash_screen.dart';
import 'package:water_potability/screens/home_screen.dart';

void main() => runApp(const WaterApp());

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Potability',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
