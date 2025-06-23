import 'package:flutter/material.dart';
import 'package:water_potability/widgets/loading_animation.dart';
import 'package:water_potability/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _start = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_start
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Water Potability',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Lottie.asset('assets/water.lottie', width: 200),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _start = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeScreen()),
                        );
                      });
                    },
                    child: const Text('Start'),
                  ),
                ],
              )
            : const LoadingAnimation(),
      ),
    );
  }
}
