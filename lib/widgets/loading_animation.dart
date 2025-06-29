import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatefulWidget {
  final bool predicting;

  const LoadingAnimation({super.key, required this.predicting});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
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

  @override
  void didUpdateWidget(covariant LoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.predicting && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.predicting && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.predicting
        ? Lottie.asset(
            'assets/water.json',
            controller: _controller,
            width: 160,
            height: 160,
            repeat: true,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
              if (widget.predicting) {
                _controller.repeat();
              }
            },
          )
        : const SizedBox.shrink();
  }
}