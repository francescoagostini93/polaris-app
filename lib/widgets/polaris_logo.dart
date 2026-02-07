import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter that draws the Polaris neuron logo (Concept 5).
/// Renders a stylized neuron with curved dendrites, a central soma,
/// and small synapse dots at the endpoints.
class NeuronLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;
  final double opacity;

  NeuronLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.glowColor = Colors.white,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor from 200x200 viewBox to actual size
    final s = min(size.width, size.height) / 200;

    // Offset to center if not square
    final dx = (size.width - 200 * s) / 2;
    final dy = (size.height - 200 * s) / 2;
    canvas.translate(dx, dy);

    // --- Dendrites (left side, flowing to soma) ---
    _drawDendrite(canvas, s, 50, 130, 70, 100, 100, 95, 1.5, 0.5);
    _drawDendrite(canvas, s, 40, 90, 65, 85, 100, 95, 1.2, 0.4);
    _drawDendrite(canvas, s, 55, 60, 75, 75, 100, 95, 1.0, 0.3);

    // --- Dendrites (right side, flowing from soma) ---
    _drawDendrite(canvas, s, 100, 95, 130, 90, 160, 70, 1.5, 0.5);
    _drawDendrite(canvas, s, 100, 95, 135, 100, 155, 120, 1.2, 0.4);
    _drawDendrite(canvas, s, 100, 95, 120, 115, 145, 150, 1.0, 0.3);

    // --- Outer ring (membrane) ---
    canvas.drawCircle(
      Offset(100 * s, 95 * s),
      18 * s,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.2 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * s,
    );

    // --- Soma (central cell body) ---
    canvas.drawCircle(
      Offset(100 * s, 95 * s),
      12 * s,
      Paint()..color = primaryColor.withValues(alpha: opacity),
    );

    // --- Synapse dots (left endpoints) ---
    _drawSynapse(canvas, s, 50, 130, 3, 0.6);
    _drawSynapse(canvas, s, 40, 90, 2.5, 0.5);
    _drawSynapse(canvas, s, 55, 60, 2, 0.4);

    // --- Synapse dots (right endpoints) ---
    _drawSynapse(canvas, s, 160, 70, 3, 0.6);
    _drawSynapse(canvas, s, 155, 120, 2.5, 0.5);
    _drawSynapse(canvas, s, 145, 150, 2, 0.4);

    // --- Inner glow ---
    canvas.drawCircle(
      Offset(100 * s, 95 * s),
      4 * s,
      Paint()..color = glowColor.withValues(alpha: 0.3 * opacity),
    );
  }

  void _drawDendrite(
    Canvas canvas,
    double s,
    double x1,
    double y1,
    double cx,
    double cy,
    double x2,
    double y2,
    double strokeWidth,
    double baseOpacity,
  ) {
    final path = Path()
      ..moveTo(x1 * s, y1 * s)
      ..quadraticBezierTo(cx * s, cy * s, x2 * s, y2 * s);

    canvas.drawPath(
      path,
      Paint()
        ..color = primaryColor.withValues(alpha: baseOpacity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * s
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSynapse(
    Canvas canvas,
    double s,
    double cx,
    double cy,
    double r,
    double baseOpacity,
  ) {
    canvas.drawCircle(
      Offset(cx * s, cy * s),
      r * s,
      Paint()..color = secondaryColor.withValues(alpha: baseOpacity * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant NeuronLogoPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor ||
      glowColor != oldDelegate.glowColor ||
      opacity != oldDelegate.opacity;
}

/// Widget that displays the Polaris neuron logo.
/// Automatically adapts colors to the current theme.
class PolarisLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double opacity;

  const PolarisLogo({
    super.key,
    this.size = 100,
    this.primaryColor,
    this.secondaryColor,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = primaryColor ??
        (isDark ? const Color(0xFF7BA3D4) : const Color(0xFF4A6FA5));
    final secondary = secondaryColor ??
        (isDark ? const Color(0xFF5B8BBF) : const Color(0xFF6B8EC2));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: NeuronLogoPainter(
          primaryColor: primary,
          secondaryColor: secondary,
          opacity: opacity,
        ),
      ),
    );
  }
}
