import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../buttons/primary_button.dart';

/// Full-screen placeholder for account-only tabs or routes while browsing as a guest.
class GuestFeatureGate extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Future<void> Function() onLogin;
  final VoidCallback? onRegister;

  const GuestFeatureGate({
    super.key,
    required this.title,
    required this.description,
    required this.onLogin,
    this.onRegister,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppColors.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'تسجيل الدخول',
                icon: Icons.login,
                onPressed: onLogin,
              ),
              if (onRegister != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRegister,
                  child: Text(
                    'إنشاء حساب جديد',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
