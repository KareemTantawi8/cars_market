import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/extensions.dart';
import 'login_screen.dart';

/// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    // TODO: Check authentication status and navigate accordingly
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.navigateToAndRemoveUntil(const LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App Logo with Blue Glow
              _buildLogo(),
              const SizedBox(height: 32),
              // App Name
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // App Tagline
              Text(
                AppConstants.appTagline,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),
              // Loading Section
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  final progress = _progressAnimation.value;
                  final percentage = (progress * 100).toInt();
                  return Column(
                    children: [
                      // Loading Text and Percentage
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'جاري التحميل...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '%$percentage',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Loading Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Premium Text
                      const Text(
                        'PREMIUM AUTOMOTIVE MARKETPLACE',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Version
                      Text(
                        'الإصدار ${AppConstants.appVersion}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Logo with Spark Plug Icons
  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18 , vertical: 36),
          child: Center(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return _buildSparkPlugIcon(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build Individual Spark Plug Icon
  Widget _buildSparkPlugIcon(int index) {
    // Top row: prongs pointing down (0, 1, 2)
    // Bottom row: prongs pointing up (3, 4, 5)
    final bool isTopRow = index < 3;
    
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

