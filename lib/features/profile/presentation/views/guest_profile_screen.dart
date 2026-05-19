import 'package:flutter/material.dart';
import '../../../../core/auth/auth_guard.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Profile tab content for guests — browse-friendly with optional sign-in.
class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 48,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تصفح كضيف',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك تصفح الإعلانات والبحث عن قطع الغيار بدون حساب. '
                'سجّل الدخول لإدارة ملفك، إعلاناتك، المحادثات والطلبات.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _BenefitTile(
                icon: Icons.directions_car_outlined,
                title: 'تصفح الإعلانات',
                subtitle: 'متاح الآن بدون تسجيل',
                available: true,
              ),
              const SizedBox(height: 12),
              _BenefitTile(
                icon: Icons.search,
                title: 'البحث عن قطع الغيار',
                subtitle: 'متاح الآن بدون تسجيل',
                available: true,
              ),
              const SizedBox(height: 12),
              _BenefitTile(
                icon: Icons.sell_outlined,
                title: 'إعلاناتي والمحادثات',
                subtitle: 'يتطلب تسجيل الدخول',
                available: false,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'تسجيل الدخول',
                icon: Icons.login,
                onPressed: () => AuthGuard.navigateToLogin(context),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إنشاء حساب جديد',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: available ? AppColors.success : context.textSecondary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            available ? Icons.check_circle : Icons.lock_outline,
            color: available ? AppColors.success : context.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
