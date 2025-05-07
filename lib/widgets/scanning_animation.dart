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
            final barHeight = 24.0; // Slightly thicker bar for better visibility
            final topPosition = animation.value * (constraints.maxHeight - barHeight);

            return Stack(
              children: [
                // Scanning bar with updated gradient and enhanced glow
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
                            // 0.3 * 255 = 76.5 → 76
                            Colors.blueAccent.withAlpha(76),
                            // 0.8 * 255 = 204
                            Colors.blueAccent.withAlpha(204),
                            // 0.3 * 255 = 76.5 → 76
                            Colors.blueAccent.withAlpha(76),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // 0.5 * 255 = 127.5 → 128
                            color: Colors.blueAccent.withAlpha(128),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(4),
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
