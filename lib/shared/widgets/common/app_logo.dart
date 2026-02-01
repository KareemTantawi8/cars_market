import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// App Logo Widget - Premium automotive marketplace logo
class AppLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const AppLogo({
    super.key,
    this.size = 100,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF2196F3), // Bright blue
            Color(0xFF1565C0), // Medium blue
            Color(0xFF0D47A1), // Dark blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 80,
                  spreadRadius: 15,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner ring decoration
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
          ),
            ),
          ),
          // Logo icon
          CustomPaint(
            size: Size(size * 0.55, size * 0.55),
            painter: _CarMarketLogoPainter(),
        ),
        ],
      ),
    );
  }
}

/// Custom Painter for Premium Car Market Logo
class _CarMarketLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // Main paint for white elements
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final whiteStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.025
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw steering wheel / gear icon hybrid
    _drawSteeringWheel(canvas, centerX, centerY, width * 0.42, whitePaint, whiteStrokePaint);
    
    // Draw car silhouette at bottom
    _drawCarSilhouette(canvas, centerX, height * 0.78, width * 0.5, whitePaint);
    
    // Draw market/store indicator (shopping bag outline at top)
    _drawMarketIndicator(canvas, centerX, height * 0.18, width * 0.22, whiteStrokePaint);
  }

  void _drawSteeringWheel(Canvas canvas, double cx, double cy, double radius, Paint fillPaint, Paint strokePaint) {
    // Outer ring
    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12;
    
    canvas.drawCircle(Offset(cx, cy), radius, outerRingPaint);
    
    // Inner hub
    canvas.drawCircle(Offset(cx, cy), radius * 0.25, fillPaint);
    
    // Spokes (3 spokes like a steering wheel)
    final spokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 - 90) * math.pi / 180;
      final innerX = cx + math.cos(angle) * radius * 0.25;
      final innerY = cy + math.sin(angle) * radius * 0.25;
      final outerX = cx + math.cos(angle) * radius * 0.85;
      final outerY = cy + math.sin(angle) * radius * 0.85;
      
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        spokePaint,
      );
    }
  }

  void _drawCarSilhouette(Canvas canvas, double cx, double cy, double width, Paint paint) {
    final carPath = Path();
    final h = width * 0.35;
    
    // Simple sleek car silhouette
    carPath.moveTo(cx - width * 0.5, cy);
    carPath.lineTo(cx - width * 0.35, cy - h * 0.3);
    carPath.quadraticBezierTo(cx - width * 0.2, cy - h, cx, cy - h);
    carPath.quadraticBezierTo(cx + width * 0.2, cy - h, cx + width * 0.35, cy - h * 0.3);
    carPath.lineTo(cx + width * 0.5, cy);
    carPath.close();
    
    canvas.drawPath(carPath, paint);
    
    // Wheels
    final wheelRadius = width * 0.08;
    canvas.drawCircle(Offset(cx - width * 0.28, cy), wheelRadius, paint);
    canvas.drawCircle(Offset(cx + width * 0.28, cy), wheelRadius, paint);
  }

  void _drawMarketIndicator(Canvas canvas, double cx, double cy, double size, Paint strokePaint) {
    // Simple price tag / market indicator
    final tagPath = Path();
    final halfSize = size / 2;
    
    // Tag shape
    tagPath.moveTo(cx - halfSize * 0.6, cy - halfSize * 0.3);
    tagPath.lineTo(cx - halfSize * 0.6, cy + halfSize * 0.8);
    tagPath.lineTo(cx + halfSize * 0.6, cy + halfSize * 0.8);
    tagPath.lineTo(cx + halfSize * 0.6, cy - halfSize * 0.3);
    tagPath.lineTo(cx, cy - halfSize * 0.8);
    tagPath.close();
    
    final tagStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(tagPath, tagStroke);
    
    // Small circle inside tag (like a price tag hole)
    canvas.drawCircle(
      Offset(cx, cy - halfSize * 0.4),
      size * 0.08,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

