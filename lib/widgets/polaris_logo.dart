import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter that draws the Polaris logo: a star whose rays are
/// neural dendrites with synapse dots — merging the concepts of
/// the North Star and a neuron in flat style.
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
    final s = min(size.width, size.height) / 200;
    final dx = (size.width - 200 * s) / 2;
    final dy = (size.height - 200 * s) / 2;
    canvas.translate(dx, dy);

    const cx = 100.0;
    const cy = 100.0;

    // ── 6 Main rays (star-neuron dendrites) ──

    // 1. North (Polaris) — longest, thickest
    _drawDendrite(canvas, s, cx, cy, 100, 26, 106, 58, 2.4, 0.7);
    _drawDendrite(canvas, s, 102, 52, 118, 38, 112, 42, 1.0, 0.4);
    _drawDendrite(canvas, s, 101, 48, 82, 32, 88, 38, 1.0, 0.38);

    // 2. NE (~60°)
    _drawDendrite(canvas, s, cx, cy, 155, 58, 132, 70, 1.7, 0.6);
    _drawDendrite(canvas, s, 135, 68, 152, 40, 146, 50, 0.9, 0.35);

    // 3. SE (~125°)
    _drawDendrite(canvas, s, cx, cy, 152, 142, 134, 116, 1.7, 0.6);
    _drawDendrite(canvas, s, 132, 120, 160, 130, 150, 124, 0.9, 0.35);

    // 4. South (~185°)
    _drawDendrite(canvas, s, cx, cy, 94, 172, 95, 140, 1.6, 0.55);
    _drawDendrite(canvas, s, 96, 148, 112, 164, 106, 158, 0.9, 0.35);

    // 5. SW (~240°)
    _drawDendrite(canvas, s, cx, cy, 46, 142, 66, 124, 1.7, 0.6);
    _drawDendrite(canvas, s, 62, 126, 36, 155, 45, 144, 0.9, 0.35);

    // 6. NW (~312°)
    _drawDendrite(canvas, s, cx, cy, 48, 54, 66, 70, 1.7, 0.6);
    _drawDendrite(canvas, s, 64, 68, 40, 40, 48, 50, 0.9, 0.35);
    _drawDendrite(canvas, s, 60, 65, 54, 38, 55, 48, 0.8, 0.3);

    // ── Soma outer ring (membrane) ──
    canvas.drawCircle(
      Offset(cx * s, cy * s),
      19 * s,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.2 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * s,
    );

    // ── Soma filled (central cell body) ──
    canvas.drawCircle(
      Offset(cx * s, cy * s),
      13 * s,
      Paint()..color = primaryColor.withValues(alpha: opacity),
    );

    // ── 4-pointed star sparkle inside soma (Polaris) ──
    _drawStarSparkle(canvas, s, cx, cy, 6, 2);

    // ── Synapse dots at main ray endpoints ──
    _drawSynapse(canvas, s, 100, 26, 3.8, 0.75); // North — bigger
    _drawSynapse(canvas, s, 155, 58, 3.0, 0.6);
    _drawSynapse(canvas, s, 152, 142, 3.0, 0.6);
    _drawSynapse(canvas, s, 94, 172, 3.0, 0.55);
    _drawSynapse(canvas, s, 46, 142, 3.0, 0.6);
    _drawSynapse(canvas, s, 48, 54, 3.0, 0.6);

    // ── Synapse dots at branch endpoints ──
    _drawSynapse(canvas, s, 118, 38, 2.2, 0.45);
    _drawSynapse(canvas, s, 82, 32, 2.0, 0.4);
    _drawSynapse(canvas, s, 152, 40, 2.0, 0.4);
    _drawSynapse(canvas, s, 160, 130, 2.0, 0.4);
    _drawSynapse(canvas, s, 112, 164, 2.0, 0.4);
    _drawSynapse(canvas, s, 36, 155, 2.0, 0.4);
    _drawSynapse(canvas, s, 40, 40, 2.0, 0.4);
    _drawSynapse(canvas, s, 54, 38, 1.8, 0.35);
  }

  /// Draw a curved dendrite line from (x1,y1) to (x2,y2) via control (cx,cy)
  void _drawDendrite(
    Canvas canvas, double s,
    double x1, double y1,
    double x2, double y2,
    double ctrlX, double ctrlY,
    double strokeWidth, double baseOpacity,
  ) {
    final path = Path()
      ..moveTo(x1 * s, y1 * s)
      ..quadraticBezierTo(ctrlX * s, ctrlY * s, x2 * s, y2 * s);

    canvas.drawPath(
      path,
      Paint()
        ..color = primaryColor.withValues(alpha: baseOpacity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * s
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Draw a synapse dot
  void _drawSynapse(
    Canvas canvas, double s,
    double x, double y,
    double r, double baseOpacity,
  ) {
    canvas.drawCircle(
      Offset(x * s, y * s),
      r * s,
      Paint()..color = secondaryColor.withValues(alpha: baseOpacity * opacity),
    );
  }

  /// Draw a 4-pointed star sparkle (Polaris accent)
  void _drawStarSparkle(
    Canvas canvas, double s,
    double cx, double cy,
    double outerR, double innerR,
  ) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 - pi / 2; // start from top
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x * s, y * s);
      } else {
        path.lineTo(x * s, y * s);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = glowColor.withValues(alpha: 0.6 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant NeuronLogoPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor ||
      glowColor != oldDelegate.glowColor ||
      opacity != oldDelegate.opacity;
}

/// Widget that displays the Polaris star-neuron logo.
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
