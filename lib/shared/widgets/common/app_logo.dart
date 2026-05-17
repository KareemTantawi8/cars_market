import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// App Logo Widget - Displays app logo image
class AppLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const AppLogo({super.key, this.size = 140, this.withGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: withGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple container if GIF fails to load
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.directions_car,
                size: size * 0.5,
                color: AppColors.primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }
}
