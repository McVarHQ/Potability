import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:potability/widgets/loading_animation.dart';
import 'package:potability/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _start = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startApp() {
    setState(() => _start = true);
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_start
            ? SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Water Potability',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Lottie.asset(
                        'assets/water.json',
                        width: 200,
                        controller: _controller,
                        onLoaded: (composition) {
                          _controller
                            ..duration = composition.duration
                            ..forward(); // Play once
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('❌ Animation failed to load');
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startApp,
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ),
              )
            : const LoadingAnimation(),
      ),
    );
  }
}
