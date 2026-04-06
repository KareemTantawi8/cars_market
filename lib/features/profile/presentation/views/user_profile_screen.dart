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
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/user_profile_cubit.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/vendor_profile_data.dart';

class UserProfileScreen extends StatelessWidget {
  final bool isEmbeddedInTab;
  const UserProfileScreen({super.key, this.isEmbeddedInTab = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit()..fetchCurrentUserProfile(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  onRetry: () =>
                      context.read<UserProfileCubit>().fetchCurrentUserProfile(),
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
                child: _ProfileContent(
                  profile: profile,
                  isEmbeddedInTab: isEmbeddedInTab,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main scrollable content
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileContent extends StatelessWidget {
  final UserProfileModel profile;
  final bool isEmbeddedInTab;
  const _ProfileContent({required this.profile, required this.isEmbeddedInTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────────
          _ProfileHeader(profile: profile, isEmbeddedInTab: isEmbeddedInTab),

          // ── White card body ────────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: context.inputBorderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Quick stats row
                    _StatsRow(profile: profile),
                    const SizedBox(height: 24),

                    // Info card
                    _InfoCard(profile: profile),

                    // Vendor section
                    if (profile.vendor != null) ...[
                      const SizedBox(height: 20),
                      _VendorSection(vendor: profile.vendor!),
                    ],

                    // Loyalty card
                    if (profile.loyaltyPoints > 0) ...[
                      const SizedBox(height: 20),
                      _LoyaltyCard(profile: profile),
                    ],

                    const SizedBox(height: 28),

                    // My Requests (customer only)
                    if (profile.userType != AppConstants.userTypeVendor) ...[
                      _SectionTitle(title: 'طلباتي'),
                      const SizedBox(height: 14),
                      _SettingTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'طلبات البحث',
                        subtitle: 'عرض طلباتك وتقييم التجار',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.mySearchRequests),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Settings section
                    _SectionTitle(title: 'الإعدادات'),
                    const SizedBox(height: 14),
                    _ThemeToggleTile(),

                    if (StorageService.getAbilities()
                        .contains('permissions.view')) ...[
                      const SizedBox(height: 12),
                      _SettingTile(
                        icon: Icons.security_outlined,
                        title: 'الصلاحيات',
                        subtitle: 'إدارة صلاحيات النظام',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.permissions),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Logout button
                    _LogoutButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header with avatar (no cover / gradient background)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;
  final bool isEmbeddedInTab;
  const _ProfileHeader({required this.profile, required this.isEmbeddedInTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isEmbeddedInTab)
                    IconButton(
                      icon: Icon(Icons.arrow_forward, color: context.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 48),
                  Text(
                    'الملف الشخصي',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _AvatarWidget(profile: profile),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: AppTextStyles.headingMedium.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeaderBadge(
                  label: profile.userType == AppConstants.userTypeVendor
                      ? 'تاجر'
                      : 'عميل',
                  color: profile.userType == AppConstants.userTypeVendor
                      ? AppColors.primaryColor
                      : AppColors.accentColor,
                ),
                if (profile.isVerified) ...[
                  const SizedBox(width: 8),
                  _HeaderBadge(
                    label: 'موثّق',
                    color: AppColors.success,
                    icon: Icons.verified,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _HeaderBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar with camera button
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final UserProfileModel profile;
  const _AvatarWidget({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.inputBorderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: profile.imageUrl != null &&
                      profile.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profile.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarFallback(context),
                      errorWidget: (_, __, ___) => _avatarFallback(context),
                    )
                  : _avatarFallback(context),
            ),
          ),
          // Camera button
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.cardBg, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      child: const Icon(Icons.person, size: 52, color: Colors.white70),
    );
  }

  void _showImageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.inputBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outlined,
                      color: AppColors.primaryColor),
                ),
                title: const Text('تغيير صورة الملف الشخصي'),
                subtitle: const Text('حد أقصى 2 ميجابايت'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final xFile = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 90,
                  );
                  if (xFile == null || !context.mounted) return;
                  final file = File(xFile.path);
                  if (!file.existsSync()) return;
                  await context
                      .read<UserProfileCubit>()
                      .uploadProfileImages(profileImage: file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick stats row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final UserProfileModel profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.info_outline,
          label: 'الحالة',
          value: profile.status == 'active' ? 'نشط' : (profile.status ?? '—'),
          valueColor:
              profile.status == 'active' ? AppColors.success : context.textSecondary,
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.badge_outlined,
          label: 'رقم المستخدم',
          value: '#${profile.id}',
        ),
        if (profile.createdAt != null) ...[
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.calendar_today_outlined,
            label: 'العضوية منذ',
            value:
                '${profile.createdAt!.year}',
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.inputBorderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? context.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card (phone, email)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final UserProfileModel profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: profile.formattedPhone,
            isFirst: true,
            isLast: profile.email == null || profile.email!.isEmpty,
          ),
          if (profile.email != null && profile.email!.isNotEmpty)
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: profile.email!,
              isFirst: false,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          Divider(
              height: 1, color: context.inputBorderColor, indent: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: AppColors.primaryColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.caption
                            .copyWith(color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vendor section
// ─────────────────────────────────────────────────────────────────────────────
class _VendorSection extends StatelessWidget {
  final VendorProfileData vendor;
  const _VendorSection({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined,
                    color: AppColors.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text('بيانات التاجر', style: AppTextStyles.headingSmall),
              const Spacer(),
              if (vendor.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('معتمد',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          if (vendor.description != null &&
              vendor.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              vendor.description!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _VendorMetric(
                  icon: Icons.star_rounded,
                  label: 'التقييم',
                  value:
                      '${vendor.averageRating} (${vendor.ratingsCount})'),
              if (vendor.responseTimeHuman != null &&
                  vendor.responseTimeHuman!.isNotEmpty) ...[
                const SizedBox(width: 12),
                _VendorMetric(
                    icon: Icons.access_time_outlined,
                    label: 'وقت الرد',
                    value: vendor.responseTimeHuman!),
              ],
            ],
          ),
          if (vendor.governorate != null ||
              (vendor.address != null && vendor.address!.isNotEmpty) ||
              (vendor.city != null && vendor.city!.isNotEmpty)) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: context.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vendor.governorate != null)
                        Text(
                          vendor.governorate!.name,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      if ((vendor.address != null && vendor.address!.isNotEmpty) ||
                          (vendor.city != null && vendor.city!.isNotEmpty)) ...[
                        if (vendor.governorate != null)
                          const SizedBox(height: 2),
                        Text(
                          [
                            if (vendor.address != null && vendor.address!.isNotEmpty)
                              vendor.address!,
                            if (vendor.city != null && vendor.city!.isNotEmpty)
                              vendor.city!,
                          ].join('، '),
                          style: AppTextStyles.caption
                              .copyWith(color: context.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (vendor.brands.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vendor.brands
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(b.name,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
          if (vendor.googleMapsUrl != null &&
              vendor.googleMapsUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(vendor.googleMapsUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('فتح في خرائط جوجل'),
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _VendorMetric(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondary)),
                  Text(value,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loyalty card
// ─────────────────────────────────────────────────────────────────────────────
class _LoyaltyCard extends StatelessWidget {
  final UserProfileModel profile;
  const _LoyaltyCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2248), AppColors.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نقاط الولاء',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 4),
                Text(
                  '${_formatPoints(profile.loyaltyPoints)} نقطة',
                  style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'استبدال',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.headingSmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme toggle tile
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final subtitle = switch (themeCubit.state) {
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
      ThemeMode.system => 'تلقائي (حسب الجهاز)',
    };
    return _SettingTile(
      icon: Icons.palette_outlined,
      title: 'المظهر',
      subtitle: subtitle,
      onTap: () => _showThemePicker(context, themeCubit),
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
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.inputBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('اختر المظهر',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 16),
              ...options.map((e) {
                final (mode, label, icon) = e;
                final isSelected = themeCubit.state == mode;
                return ListTile(
                  leading: Icon(icon,
                      color: isSelected
                          ? AppColors.primaryColor
                          : context.textSecondary),
                  title: Text(label,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primaryColor)
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic setting tile
// ─────────────────────────────────────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.inputBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(color: context.textSecondary)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout button
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleLogout(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('تسجيل الخروج', style: AppTextStyles.headingSmall),
        content: Text('هل أنت متأكد من تسجيل الخروج؟',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () => NavigationService.navigateToLogout(context),
            child: Text('تسجيل الخروج',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
