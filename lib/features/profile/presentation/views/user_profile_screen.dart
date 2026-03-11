import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/user_profile_cubit.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/vendor_profile_data.dart';

/// User Profile Screen
class UserProfileScreen extends StatelessWidget {
  /// When true, screen is shown as a tab (e.g. in home bottom nav); back button is hidden.
  final bool isEmbeddedInTab;

  const UserProfileScreen({super.key, this.isEmbeddedInTab = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit()..fetchCurrentUserProfile(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
          title: Text(
            'الملف الشخصي',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: isEmbeddedInTab
              ? null
              : [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
        ),
        body: BlocConsumer<UserProfileCubit, UserProfileState>(
          listener: (context, state) {
            if (state is UserProfileImagesUploaded) {
              CustomToast.showSuccess(context, 'تم تحديث الصورة بنجاح');
            }
          },
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

            if (state is UserProfileLoaded || state is UserProfileImagesUploaded) {
              final profile = state is UserProfileLoaded
                  ? state.profile
                  : (state as UserProfileImagesUploaded).profile;
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<UserProfileCubit>().fetchCurrentUserProfile(),
                child: _buildProfileContent(context, profile),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfileModel profile) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture and Info
            _buildProfileSection(context, profile),
            if (profile.vendor != null) ...[
              const SizedBox(height: 24),
              _buildVendorSection(context, profile.vendor!),
            ],
            const SizedBox(height: 24),
            // Loyalty Program Card
            _buildLoyaltyProgramCard(context, profile),
            const SizedBox(height: 24),
            // Account Settings
            _buildAccountSettingsSection(context, profile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profile.backgroundImageUrl != null && profile.backgroundImageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _showChangeProfileImageSheet(context),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: profile.backgroundImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: context.surfaceBg, child: Icon(Icons.photo_library, color: context.textSecondary, size: 40)),
                  errorWidget: (_, __, ___) => Container(color: context.surfaceBg, child: Icon(Icons.photo_library, color: context.textSecondary, size: 40)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
          // Profile Picture (tappable to change)
          GestureDetector(
            onTap: () => _showChangeProfileImageSheet(context),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceBg,
                  ),
                  child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: context.surfaceBg,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: context.textSecondary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 60,
                              color: context.textSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: context.textSecondary,
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
                      child: Icon(
                        Icons.check,
                        color: context.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            profile.name,
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
            context,
            icon: Icons.phone,
            label: 'رقم الهاتف',
            value: profile.formattedPhone,
          ),
          const SizedBox(height: 12),
          if (profile.email != null && profile.email!.isNotEmpty)
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: profile.email!,
            ),
          if (profile.email != null && profile.email!.isNotEmpty)
            const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.badge,
            label: 'رقم المستخدم',
            value: '#${profile.id}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            icon: Icons.info_outline,
            label: 'حالة الحساب',
            value: profile.status == 'active'
                ? 'نشط'
                : profile.status ?? 'غير معروف',
            valueColor: profile.status == 'active'
                ? AppColors.success
                : context.textSecondary,
          ),
          if (profile.createdAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'تاريخ التسجيل',
              value: _formatDate(profile.createdAt!),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeProfileImageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('تغيير صورة الملف الشخصي'),
                subtitle: const Text('حد أقصى 2 ميجابايت، jpg/png/webp'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picker = ImagePicker();
                  final xFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 90,
                  );
                  if (xFile == null || !context.mounted) return;
                  final file = File(xFile.path);
                  if (!file.existsSync()) return;
                  await context.read<UserProfileCubit>().uploadProfileImages(profileImage: file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('تغيير صورة الخلفية'),
                subtitle: const Text('حد أقصى 4 ميجابايت، jpg/png/webp'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picker = ImagePicker();
                  final xFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 90,
                  );
                  if (xFile == null || !context.mounted) return;
                  final file = File(xFile.path);
                  if (!file.existsSync()) return;
                  await context.read<UserProfileCubit>().uploadProfileImages(backgroundImage: file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorSection(BuildContext context, VendorProfileData vendor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'بيانات التاجر',
                style: AppTextStyles.headingSmall,
              ),
              if (vendor.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'معتمد',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (vendor.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'متصل',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (vendor.description != null && vendor.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                vendor.description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          // Metrics row
          Row(
            children: [
              _buildVendorMetric(
                context,
                icon: Icons.star,
                label: 'التقييم',
                value: '${vendor.averageRating} (${vendor.ratingsCount})',
              ),
              const SizedBox(width: 16),
              if (vendor.responseTimeHuman != null &&
                  vendor.responseTimeHuman!.isNotEmpty)
                _buildVendorMetric(
                  context,
                  icon: Icons.access_time,
                  label: 'وقت الرد',
                  value: vendor.responseTimeHuman!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (vendor.address != null && vendor.address!.isNotEmpty)
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'العنوان',
              value: [
                vendor.address,
                vendor.city,
                vendor.governorate?.name,
              ].whereType<String>().where((s) => s.isNotEmpty).join('، '),
            ),
          if (vendor.address != null && vendor.address!.isNotEmpty)
            const SizedBox(height: 12),
          if (vendor.governorate != null)
            _buildInfoRow(
              context,
              icon: Icons.map,
              label: 'المحافظة',
              value: vendor.governorate!.name,
            ),
          if (vendor.governorate != null) const SizedBox(height: 12),
          if (vendor.brands.isNotEmpty) ...[
            Text(
              'العلامات التجارية',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vendor.brands
                  .map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (vendor.googleMapsUrl != null &&
              vendor.googleMapsUrl!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(vendor.googleMapsUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map),
              label: const Text('فتح في خرائط جوجل'),
            ),
        ],
      ),
    );
  }

  Widget _buildVendorMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? context.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: context.textSecondary),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Format: يوم/شهر/سنة
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLoyaltyProgramCard(
    BuildContext context,
    UserProfileModel profile,
  ) {
    // Only show loyalty program if user has points or if it's a feature
    if (profile.loyaltyPoints <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: context.textPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('نقاطي', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 4),
                    Text(
                      'رصيد النقاط الحالي: ${_formatPoints(profile.loyaltyPoints)} نقطة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
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

  Widget _buildAccountSettingsSection(
    BuildContext context,
    UserProfileModel profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('إعدادات الحساب', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        _buildSettingItem(
          context: context,
          icon: Icons.person,
          title: 'تعديل الملف الشخصي',
          subtitle: 'الاسم، رقم الهاتف، العنوان',
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          context: context,
          icon: Icons.language,
          title: 'اللغة',
          subtitle: 'العربية (مصر)',
          onTap: () {
            // TODO: Navigate to lanqguage settings
          },
        ),
        const SizedBox(height: 12),
        _buildThemeSettingItem(context),
        const SizedBox(height: 12),
        _buildSettingItem(
          context: context,
          icon: Icons.help_outline,
          title: 'المساعدة والدعم',
          subtitle: 'الأسئلة الشائعة، تواصل معنا',
          onTap: () {
            // TODO: Navigate to help and support
          },
        ),
        const SizedBox(height: 20),
        Text('أخرى', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        if (StorageService.getAbilities().contains('permissions.view'))
          _buildSettingItem(
            context: context,
            icon: Icons.security,
            title: 'الصلاحيات',
            subtitle: 'إدارة صلاحيات النظام',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.permissions);
            },
          ),
        if (StorageService.getAbilities().contains('permissions.view')) const SizedBox(height: 12),
        _buildSettingItem(
          context: context,
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

  Widget _buildThemeSettingItem(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = switch (themeCubit.state) {
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
      ThemeMode.system => 'تلقائي (حسب الجهاز)',
    };
    return InkWell(
      onTap: () => _showThemePicker(context, themeCubit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المظهر',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeCubit themeCubit) {
    final options = [
      (ThemeMode.light, 'فاتح', Icons.light_mode_outlined),
      (ThemeMode.dark, 'داكن', Icons.dark_mode_outlined),
      (ThemeMode.system, 'تلقائي', Icons.brightness_auto_outlined),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر المظهر',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...options.map((e) {
                  final (mode, label, icon) = e;
                  final isSelected = themeCubit.state == mode;
                  return ListTile(
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(ctx).colorScheme.primary
                          : Theme.of(
                              ctx,
                            ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      themeCubit.setThemeMode(mode);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.5),
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
        backgroundColor: context.cardBg,
        title: Text('تسجيل الخروج', style: AppTextStyles.headingSmall),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: AppTextStyles.link),
          ),
          TextButton(
            onPressed: () {
              NavigationService.navigateToLogout(context);
            },
            child: Text(
              'تسجيل الخروج',
              style: AppTextStyles.link.copyWith(color: AppColors.error),
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
