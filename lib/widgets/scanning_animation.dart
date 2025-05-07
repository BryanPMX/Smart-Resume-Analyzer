// scanning_animation.dart
import 'package:flutter/material.dart';

/// Widget that displays a dynamic scanning animation overlay with a moving bar.
class ScanningAnimation extends StatelessWidget {
  final AnimationController controller;

  const ScanningAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Animation for the scanning bar's vertical position (0.0 to 1.0)
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.linear,
          ),
        );

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // Calculate the bar's top position based on the animation value
            final barHeight = 20.0;
            final topPosition = animation.value * (constraints.maxHeight - barHeight);

            return Stack(
              children: [
                // Subtle blur overlay for text behind the bar
                Positioned(
                  top: topPosition + barHeight,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight - topPosition - barHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    ),
                  ),
                ),
                // Scanning bar with gradient and glow
                Positioned(
                  top: topPosition,
                  left: 0,
                  right: 0,
                  height: barHeight,
                  child: RepaintBoundary(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.withAlpha((0.2 * 255).toInt()),
                            Colors.indigo.withAlpha((0.6 * 255).toInt()),
                            Colors.indigo.withAlpha((0.2 * 255).toInt()),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withAlpha((0.4 * 255).toInt()),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}