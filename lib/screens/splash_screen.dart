import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:potability/screens/home_screen.dart';

const Color startColor = Color(0xFF486097);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool showStart = false;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      if (_controller.value >= 0.48 && !showStart && !hasStarted) {
        _controller.stop();
        setState(() => showStart = true);
        _controller.repeat(
          min: 0.45,
          max: 0.48,
          reverse: true,
          period: const Duration(seconds: 2),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startApp() {
    setState(() {
      hasStarted = true;
      showStart = false;
    });

    _controller.stop();
    _controller.forward(from: _controller.value);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fullscreen Lottie background
          SizedBox(
            height: screenSize.height,
            width: screenSize.width,
            child: Lottie.asset(
              'assets/water_full.json',
              controller: _controller,
              fit: BoxFit.cover,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _controller.forward();
              },
            ),
          ),

          // START text only (no box, no background)
          if (showStart)
            Center(
              child: GestureDetector(
                onTap: _startApp,
                child: Text(
                  "START",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SairaExpanded',
                    color: startColor,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}