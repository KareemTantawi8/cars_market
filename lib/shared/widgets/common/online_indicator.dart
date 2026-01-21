import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Online/Offline Status Indicator
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.backgroundColor,
          width: 2,
        ),
      ),
    );
  }
}

