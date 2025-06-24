import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:potability/screens/home_screen.dart';

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
      if (_controller.value >= 0.5 && !showStart && !hasStarted) {
        _controller.stop();
        setState(() {
          showStart = true;
        });
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

    _controller.forward(from: _controller.value);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
          // Lottie animation stretched to fill the screen
          SizedBox(
            height: screenSize.height,
            width: screenSize.width,
            child: Lottie.asset(
              'assets/water_full.json',
              controller: _controller,
              fit: BoxFit.cover,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward();
              },
            ),
          ),

          // START button overlay
          if (showStart)
            Center(
              child: ElevatedButton(
                onPressed: _startApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF486097),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SairaExpanded', // 👈 Use your custom font
                  ),
                ),
                child: const Text("START"),
              ),
            ),
        ],
      ),
    );
  }
}
