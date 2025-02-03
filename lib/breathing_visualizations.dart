import 'package:flutter/material.dart';
import 'dart:math' as math;

// Circular Visualization
class CircularBreathingIndicator extends StatelessWidget {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  const CircularBreathingIndicator({
    super.key,
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: CircularBreathingPainter(
          bar1Value: bar1Value,
          bar2Value: bar2Value,
          bar3Value: bar3Value,
          phase: phase,
        ),
      ),
    );
  }
}

class CircularBreathingPainter extends CustomPainter {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  CircularBreathingPainter({
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    // Draw background arcs
    paint.color = Colors.grey[300]!;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi / 3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi / 6,
      2 * math.pi / 3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      5 * math.pi / 6,
      2 * math.pi / 3,
      false,
      paint,
    );

    // Draw progress arcs
    paint.color = Colors.blue;
    if (phase == 1) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        -math.pi / 2,
        2 * math.pi / 3 * bar1Value,
        false,
        paint,
      );
    } else if (phase == 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        math.pi / 6,
        2 * math.pi / 3 * bar2Value,
        false,
        paint,
      );
    } else if (phase == 3) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        5 * math.pi / 6,
        2 * math.pi / 3 * bar3Value,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Triangle Visualization
class TriangleBreathingIndicator extends StatelessWidget {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  const TriangleBreathingIndicator({
    super.key,
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: TriangleBreathingPainter(
          bar1Value: bar1Value,
          bar2Value: bar2Value,
          bar3Value: bar3Value,
          phase: phase,
        ),
      ),
    );
  }
}

class TriangleBreathingPainter extends CustomPainter {
  final double bar1Value;
  final double bar2Value;
  final double bar3Value;
  final int phase;

  TriangleBreathingPainter({
    required this.bar1Value,
    required this.bar2Value,
    required this.bar3Value,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    final double triangleHeight = size.height * 0.8;
    final double triangleBase = size.width * 0.8;
    final double startX = size.width * 0.1;
    final double startY = size.height * 0.9;

    // Draw background lines
    paint.color = Colors.grey[300]!;
    // Bottom line
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + triangleBase, startY),
      paint,
    );
    // Right line
    canvas.drawLine(
      Offset(startX + triangleBase, startY),
      Offset(startX + triangleBase / 2, startY - triangleHeight),
      paint,
    );
    // Left line
    canvas.drawLine(
      Offset(startX + triangleBase / 2, startY - triangleHeight),
      Offset(startX, startY),
      paint,
    );

    // Draw progress lines
    paint.color = Colors.blue;
    if (phase == 1) {
      // Bottom line progress
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + (triangleBase * bar1Value), startY),
        paint,
      );
    } else if (phase == 2) {
      // Right line progress
      final double progressX =
          startX + triangleBase - (triangleBase * bar2Value / 2);
      final double progressY = startY - (triangleHeight * bar2Value);
      canvas.drawLine(
        Offset(startX + triangleBase, startY),
        Offset(progressX, progressY),
        paint,
      );
    } else if (phase == 3) {
      // Left line progress
      final double progressX =
          startX + triangleBase / 2 - (triangleBase * bar3Value / 2);
      final double progressY =
          startY - triangleHeight + (triangleHeight * bar3Value);
      canvas.drawLine(
        Offset(startX + triangleBase / 2, startY - triangleHeight),
        Offset(progressX, progressY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
