import 'package:flutter/material.dart';

/// A full-screen scanning effect that animates a horizontal beam
/// moving from top to bottom.
///
/// The beam is rendered as a gradient band for a sleek “scanner” look,
/// and the background is slightly dimmed for emphasis.
class ScanningAnimation extends StatelessWidget {
  /// Controls the vertical position of the scanning beam (0.0 to 1.0).
  final AnimationController controller;

  /// Color of the scanning beam.
  final Color beamColor;

  /// Height of the scanning beam in pixels.
  final double beamHeight;

  const ScanningAnimation({
    super.key,
    required this.controller,
    this.beamColor = Colors.indigoAccent,
    this.beamHeight = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ScanPainter(
              progress: controller.value,
              beamColor: beamColor,
              beamHeight: beamHeight,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double progress;
  final Color beamColor;
  final double beamHeight;

  const _ScanPainter({
    required this.progress,
    required this.beamColor,
    required this.beamHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dim the background slightly (20% opacity) using explicit alpha
    final overlayPaint = Paint()
      ..color = Colors.black.withAlpha((0.2 * 255).round());
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Compute the vertical center of the beam
    final yCenter = size.height * progress;
    final top = yCenter - beamHeight / 2;
    final bottom = yCenter + beamHeight / 2;
    final beamRect = Rect.fromLTRB(0, top, size.width, bottom);

    // Create a vertical gradient for the beam:
    // transparent → semi‑opaque beamColor → transparent
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        beamColor.withAlpha(0),                           // fully transparent
        beamColor.withAlpha((0.6 * 255).round()),         // 60% opacity
        beamColor.withAlpha(0),                           // back to transparent
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(beamRect);

    // Paint the beam with an additive blend for a glow effect
    final beamPaint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus;

    canvas.drawRect(beamRect, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) {
    return old.progress != progress ||
        old.beamColor != beamColor ||
        old.beamHeight != beamHeight;
  }
}