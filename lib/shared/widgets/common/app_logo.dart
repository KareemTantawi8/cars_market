import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// App Logo Widget - Reusable logo with spark plug icons
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
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryDark,
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return _SparkPlugIcon(isTopRow: index < 3);
          },
        ),
      ),
    );
  }
}

/// Individual Spark Plug Icon
class _SparkPlugIcon extends StatelessWidget {
  final bool isTopRow;

  const _SparkPlugIcon({required this.isTopRow});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SparkPlugPainter(isTopRow: isTopRow),
    );
  }
}

/// Custom Painter for Spark Plug Icon
class SparkPlugPainter extends CustomPainter {
  final bool isTopRow;

  SparkPlugPainter({required this.isTopRow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    if (isTopRow) {
      // Prongs pointing down
      // Top connector (wider)
      canvas.drawRect(
        Rect.fromLTWH(centerX - width * 0.25, 0, width * 0.5, height * 0.4),
        paint,
      );
      // Stem (narrower)
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - width * 0.15,
          height * 0.4,
          width * 0.3,
          height * 0.6,
        ),
        paint,
      );
      // Prongs (two at bottom)
      final prongWidth = width * 0.08;
      final prongGap = width * 0.1;
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - prongGap - prongWidth,
          height * 0.85,
          prongWidth,
          height * 0.15,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          centerX + prongGap,
          height * 0.85,
          prongWidth,
          height * 0.15,
        ),
        paint,
      );
    } else {
      // Prongs pointing up
      // Bottom connector (wider)
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - width * 0.25,
          height * 0.6,
          width * 0.5,
          height * 0.4,
        ),
        paint,
      );
      // Stem (narrower)
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - width * 0.15,
          0,
          width * 0.3,
          height * 0.6,
        ),
        paint,
      );
      // Prongs (two at top)
      final prongWidth = width * 0.08;
      final prongGap = width * 0.1;
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - prongGap - prongWidth,
          0,
          prongWidth,
          height * 0.15,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          centerX + prongGap,
          0,
          prongWidth,
          height * 0.15,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

