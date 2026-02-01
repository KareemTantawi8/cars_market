import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/controllers/user_type_controller.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/common/app_logo.dart';
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
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Initialize storage service and user type controller
    await StorageService.init();
    await UserTypeController().initialize();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Always navigate to login screen - user must login every time
        context.navigateToAndRemoveUntil(const LoginScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
              ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  const SizedBox(height: 40),
              // App Logo with Blue Glow
                  const AppLogo(size: 140, withGlow: true),
                  const SizedBox(height: 24),
              // App Name
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                      letterSpacing: 1.2,
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
                  const SizedBox(height: 60),
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
                            Text(
                              'جاري التحميل...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '%$percentage',
                              style: TextStyle(
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
                      Text(
                        'PREMIUM AUTOMOTIVE MARKETPLACE',
                        style: TextStyle(
                              fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
                  const SizedBox(height: 20),
        ],
      ),
            ),
          ),
        ),
      ),
    );
  }

}

