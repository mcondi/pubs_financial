import 'dart:math' as math;
import 'package:flutter/material.dart';

class StockGauge extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final bool lowerBetter;

  const StockGauge({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.lowerBetter,
  });

  Color _bandColor(double v) {
    if (lowerBetter) {
      if (v <= 2) return const Color(0xFF54D65A);
      if (v <= 4) return const Color(0xFFFFD54D);
      return const Color(0xFF53B0FF);
    } else {
      if (v >= 12) return const Color(0xFF54D65A);
      if (v >= 8) return const Color(0xFFFFD54D);
      return const Color(0xFF53B0FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final t = (clamped - min) / (max - min);
    final angle = math.pi * (1 - t);
    final valueText = '${value.toStringAsFixed(1)}$suffix';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102E4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ✅ Give the painter a little breathing room so it never overflows
          AspectRatio(
            aspectRatio: 1.60,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10), // <- key fix
              child: CustomPaint(
                painter: _GaugePainter(angle: angle, color: _bandColor(value)),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
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

class _GaugePainter extends CustomPainter {
  final double angle;
  final Color color;

  _GaugePainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Pull center up a bit, shrink radius slightly to avoid any stroke/needle overflow
    final center = Offset(size.width / 2, size.height * 0.70);
    final radius = math.min(size.width, size.height) * 0.52;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B4B66);

    final progPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color;

    // base arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      basePaint,
    );

    // progress arc
    final sweep = math.pi - angle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweep,
      false,
      progPaint,
    );

    // needle
    final needlePaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final needleLen = radius * 0.86;
    final needleEnd = Offset(
      center.dx + needleLen * math.cos(angle),
      center.dy - needleLen * math.sin(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}
