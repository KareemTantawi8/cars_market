import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/controllers/user_type_controller.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/user_profile_cubit.dart';
import '../../data/models/user_profile_model.dart';
import '../../../../shared/widgets/debug/user_type_switcher.dart';

/// User Profile Screen
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit()..fetchCurrentUserProfile(),
      child: Scaffold(
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
        body: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoading) {
              return const Center(child: LoadingIndicator());
            }

            if (state is UserProfileError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () {
                    context.read<UserProfileCubit>().fetchCurrentUserProfile();
                  },
                ),
              );
            }

            if (state is UserProfileLoaded) {
              return _buildProfileContent(context, state.profile);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfileModel profile) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture and Info
            _buildProfileSection(profile),
            const SizedBox(height: 24),
            // Loyalty Program Card
            _buildLoyaltyProgramCard(profile),
            const SizedBox(height: 24),
            // Account Settings
            _buildAccountSettingsSection(context, profile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceColor,
                ),
                child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profile.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surfaceColor,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
              ),
              if (profile.isVerified)
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
                      Icons.check,
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
            profile.name,
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          // User Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: profile.userType == AppConstants.userTypeVendor
                  ? AppColors.primaryColor.withOpacity(0.2)
                  : AppColors.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.userType == AppConstants.userTypeVendor ? 'تاجر' : 'عميل',
              style: AppTextStyles.bodySmall.copyWith(
                color: profile.userType == AppConstants.userTypeVendor
                    ? AppColors.primaryColor
                    : AppColors.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User Info
          _buildInfoRow(
            icon: Icons.phone,
            label: 'رقم الهاتف',
            value: profile.formattedPhone,
          ),
          const SizedBox(height: 12),
          if (profile.email != null && profile.email!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: profile.email!,
            ),
          if (profile.email != null && profile.email!.isNotEmpty)
            const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.badge,
            label: 'رقم المستخدم',
            value: '#${profile.id}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.info_outline,
            label: 'حالة الحساب',
            value: profile.status == 'active' ? 'نشط' : profile.status ?? 'غير معروف',
            valueColor: profile.status == 'active' ? AppColors.success : AppColors.textSecondary,
          ),
          if (profile.createdAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'تاريخ التسجيل',
              value: _formatDate(profile.createdAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Format: يوم/شهر/سنة
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLoyaltyProgramCard(UserProfileModel profile) {
    // Only show loyalty program if user has points or if it's a feature
    if (profile.loyaltyPoints <= 0) {
      return const SizedBox.shrink();
    }

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
                      'رصيد النقاط الحالي: ${_formatPoints(profile.loyaltyPoints)} نقطة',
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

  Widget _buildAccountSettingsSection(BuildContext context, UserProfileModel profile) {
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

  String _formatPoints(int points) {
    // Format points with thousand separators
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
