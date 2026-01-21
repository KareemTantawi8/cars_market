import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/controllers/user_type_controller.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';
import '../../../../shared/widgets/debug/user_type_switcher.dart';

/// User Profile Screen
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _currentNavIndex = 3; // Account is at index 3

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Navigate to settings
          },
        ),
        title: Text(
          'الملف الشخصي',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Picture and Info
              _buildProfileSection(),
              const SizedBox(height: 24),
              // Loyalty Program Card
              _buildLoyaltyProgramCard(),
              const SizedBox(height: 24),
              // Account Settings
              _buildAccountSettingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Profile Picture
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink.shade100,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.pink,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          'أحمد محمد',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 4),
        // Phone/ID
        Text(
          '5678 234 101 20+',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyProgramCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'برنامج الولاء',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: AppColors.textPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نقاطي',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'رصيد النقاط الحالي: 1,250 نقطة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'استبدال النقاط',
            onPressed: () {
              // TODO: Navigate to redeem points
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إعدادات الحساب',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        _buildSettingItem(
          icon: Icons.person,
          title: 'تعديل الملف الشخصي',
          subtitle: 'الاسم، رقم الهاتف، العنوان',
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.language,
          title: 'اللغة',
          subtitle: 'العربية (مصر)',
          onTap: () {
            // TODO: Navigate to language settings
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.help_outline,
          title: 'المساعدة والدعم',
          subtitle: 'الأسئلة الشائعة، تواصل معنا',
          onTap: () {
            // TODO: Navigate to help and support
          },
        ),
        const SizedBox(height: 20),
        Text(
          'أخرى',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        // Debug: User Type Switcher
        InkWell(
          onTap: () {
            UserTypeSwitcher.showBottomSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'تبديل نوع المستخدم',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEBUG',
                              style: AppTextStyles.captionSmall.copyWith(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ListenableBuilder(
                        listenable: UserTypeController(),
                        builder: (context, child) {
                          final controller = UserTypeController();
                          return Text(
                            'النوع الحالي: ${controller.userTypeDisplayName}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.logout,
          title: 'تسجيل الخروج',
          subtitle: '',
          iconColor: AppColors.error,
          onTap: () {
            _handleLogout(context);
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primaryColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'الرئيسية', 0, () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  }),
                  _buildNavItem(Icons.search, 'البحث', 1, () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  }),
                  _buildNavItem(Icons.shopping_cart, 'الطلبات', 2, () {
                    // TODO: Navigate to orders
                  }),
                  _buildNavItem(Icons.person, 'حسابي', 3, () {}),
                ],
              ),
            ),
            // Footer with version
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${AppConstants.appName} - نسخة ${AppConstants.appVersion}',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = index == _currentNavIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentNavIndex = index);
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text(
          'تسجيل الخروج',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.link,
            ),
          ),
          TextButton(
            onPressed: () {
              NavigationService.navigateToLogout(context);
            },
            child: Text(
              'تسجيل الخروج',
              style: AppTextStyles.link.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

