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
  bool showStartAndLogo = false;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      // Show START text and logo after 50% mark and pause animation
      if (_controller.value >= 0.5 && !showStartAndLogo && !hasStarted) {
        _controller.stop(); // Pause the animation
        setState(() => showStartAndLogo = true);
        
        // Start floating animation between 0.48 and 0.52
        _controller.repeat(
          min: 0.40,
          max: 0.45,
          reverse: true,
          period: const Duration(seconds: 1),
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
      showStartAndLogo = false; // Hide both START text and logo
    });

    // Stop floating animation and continue to completion
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

          // University Logo at bottom - only show when showStartAndLogo is true
          if (showStartAndLogo)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/uni_logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // START text spanning screen width - only show when showStartAndLogo is true
          if (showStartAndLogo)
            Center(
              child: GestureDetector(
                onTap: _startApp,
                child: SizedBox(
                  width: screenSize.width * 0.9, // Use 90% of screen width
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                      "START",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SairaExpanded',
                        color: startColor,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}