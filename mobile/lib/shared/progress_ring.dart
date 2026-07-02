import 'package:flutter/material.dart';
import 'dart:math';

class ProgressRing extends StatelessWidget {
  final double progress;

  const ProgressRing({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140, // ✨ Lebih besar sedikit
      height: 140,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(seconds: 2), // ✨ Animasi 2 detik
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _ProgressPainter(value),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${value.toInt()}%",
                    style: const TextStyle(
                      fontSize: 32, // ✨ Font lebih besar
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    "Kehadiran",
                    style: TextStyle(
                      fontSize: 13, 
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;

  _ProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0; // ✨ Garis lebih tebal dan bold
    final radius = (size.width / 2) - strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);

    /// 🔥 BACKGROUND (FULL CIRCLE)
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    /// 🔥 PROGRESS (FULL RING STYLE WITH GLOW)
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = const SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [
        Color(0xFF60A5FA), // Light Blue
        Color(0xFF2563EB), // Blue
        Color(0xFF4F46E5), // Indigo
      ],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded edges

    final sweepAngle = 2 * pi * (progress / 100);

    // Removed drawShadow because it causes the inside of the ring to be filled with a grayish color

    canvas.drawArc(
      rect,
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
