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
import '../../../../shared/widgets/common/rating_stars.dart';
import '../cubit/user_profile_cubit.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/vendor_profile_data.dart';
import '../../../ads/data/repositories/ads_repository.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/my_ads_cubit.dart';
import '../../../my_ads/presentation/views/my_ads_screen.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../../home/data/models/category_models.dart';

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

                    // Phone + email (phone for vendors is detailed in [_VendorDetailsCard])
                    _InfoCard(
                      profile: profile,
                      hidePhone:
                          profile.userType == AppConstants.userTypeVendor &&
                              profile.vendor != null,
                      includeNameRow:
                          profile.userType != AppConstants.userTypeVendor,
                    ),
                    const SizedBox(height: 16),
                    _AddressSection(profile: profile),

                    // Vendor — full detail: name, phone, rating, brands, address, response, verified…
                    if (profile.userType == AppConstants.userTypeVendor &&
                        profile.vendor != null) ...[
                      const SizedBox(height: 20),
                      _VendorDetailsCard(profile: profile),
                    ],

                    // إعلانات المستخدم (تاجر أو عميل) — يُعاد الجلب عند تحديث الملف عبر السحب
                    const SizedBox(height: 20),
                    _ProfileLinkedAdsSection(
                      key: ValueKey(
                        '${profile.id}_${profile.updatedAt?.millisecondsSinceEpoch ?? 0}',
                      ),
                    ),

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
                      fontSize: 21,
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
                fontSize: 24,
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
                if (profile.userType == AppConstants.userTypeVendor &&
                    profile.isVerified) ...[
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.inputBorderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.primaryColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? context.textPrimary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
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
  /// When true, phone is shown in the vendor detail card instead.
  final bool hidePhone;
  /// Shows explicit name row (used for customer accounts).
  final bool includeNameRow;

  const _InfoCard({
    required this.profile,
    this.hidePhone = false,
    this.includeNameRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = profile.phone.trim().isNotEmpty;
    final showPhone = hasPhone && !hidePhone;
    final hasEmail = profile.email != null && profile.email!.isNotEmpty;
    if (!includeNameRow && !showPhone && !hasEmail) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        children: [
          if (includeNameRow)
            _InfoTile(
              icon: Icons.person_outline_rounded,
              label: 'الاسم',
              value: profile.name.isNotEmpty ? profile.name : '—',
              isFirst: true,
              isLast: false,
            ),
          if (showPhone)
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'رقم الهاتف',
              value: profile.formattedPhone,
              isFirst: !includeNameRow,
              isLast: !hasEmail,
            ),
          if (hasEmail)
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: profile.email!,
              isFirst: !includeNameRow && !showPhone,
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
                            .copyWith(
                              color: context.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            )),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.5,
                      ),
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
// Vendor — detailed fields (aligned with product spec)
// ─────────────────────────────────────────────────────────────────────────────
class _VendorDetailsCard extends StatelessWidget {
  final UserProfileModel profile;

  const _VendorDetailsCard({required this.profile});

  VendorProfileData get _v => profile.vendor!;

  String _shopPhoneLine() {
    final raw = _v.phone?.trim();
    if (raw == null || raw.isEmpty) return '';
    final user = profile.phone.trim();
    if (user.isNotEmpty && raw.replaceAll(RegExp(r'\D'), '') ==
        user.replaceAll(RegExp(r'\D'), '')) {
      return '';
    }
    return raw;
  }

  String _addressLine() {
    final parts = <String>[];
    if (_v.governorate != null) parts.add(_v.governorate!.name);
    if (_v.address != null && _v.address!.trim().isNotEmpty) {
      parts.add(_v.address!.trim());
    }
    if (_v.city != null && _v.city!.trim().isNotEmpty) {
      parts.add(_v.city!.trim());
    }
    return parts.join(' — ');
  }

  String _responseLine() {
    final h = _v.responseTimeHuman?.trim();
    if (h != null && h.isNotEmpty) return h;
    final hrs = _v.responseTimeHours;
    if (hrs != null && hrs > 0) return '$hrs ساعة';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    final shopExtra = _shopPhoneLine();
    final addressText = _addressLine();

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
              Expanded(
                child: Text(
                  'تفاصيل التاجر',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (v.isVerified)
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
                      Text(
                        'موثّق',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _VendorField(
            icon: Icons.person_outline_rounded,
            label: 'الاسم',
            value: profile.name.isNotEmpty ? profile.name : '—',
          ),
          if (v.companyName.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _VendorField(
              icon: Icons.store_mall_directory_outlined,
              label: 'اسم المحل / الشركة',
              value: v.companyName.trim(),
            ),
          ],
          if (profile.phone.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _VendorField(
              icon: Icons.phone_outlined,
              label: 'رقم الهاتف',
              value: profile.formattedPhone,
              valueLtr: true,
            ),
          ],
          if (shopExtra.isNotEmpty) ...[
            const SizedBox(height: 14),
            _VendorField(
              icon: Icons.call_rounded,
              label: 'هاتف المتجر',
              value: shopExtra,
              valueLtr: true,
            ),
          ],
          const SizedBox(height: 14),
          _VendorField(
            icon: Icons.star_rounded,
            label: 'التقييم',
            child: Row(
              children: [
                RatingStars(
                  rating: v.averageRating,
                  reviewCount: v.ratingsCount,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  v.averageRating.toStringAsFixed(1),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ratingStar,
                  ),
                ),
              ],
            ),
          ),
          if (v.brands.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'الماركات',
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: v.brands
                  .map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.name,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (addressText.isNotEmpty) ...[
            const SizedBox(height: 14),
            _VendorField(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: addressText,
            ),
          ],
          const SizedBox(height: 14),
          _VendorField(
            icon: Icons.speed_rounded,
            label: 'سرعة الرد',
            value: _responseLine(),
            valueColor: AppColors.primaryColor,
          ),
          const SizedBox(height: 14),
          _VendorField(
            icon: Icons.verified_outlined,
            label: 'حالة الحساب',
            value: v.isVerified ? 'موثّق من المنصة' : 'غير موثّق',
            valueColor: v.isVerified ? AppColors.success : context.textSecondary,
          ),
          if (v.description != null && v.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'نبذة',
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              v.description!.trim(),
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (v.googleMapsUrl != null && v.googleMapsUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(v.googleMapsUrl!);
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

class _VendorField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final bool valueLtr;
  final Color? valueColor;

  const _VendorField({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.valueLtr = false,
    this.valueColor,
  }) : assert(value != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (child != null)
                child!
              else
                Text(
                  value!,
                  textDirection:
                      valueLtr ? TextDirection.ltr : TextDirection.rtl,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: valueColor ?? context.textPrimary,
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
// إعلاناتي — من GET /my-ads
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileLinkedAdsSection extends StatefulWidget {
  const _ProfileLinkedAdsSection({super.key});

  @override
  State<_ProfileLinkedAdsSection> createState() =>
      _ProfileLinkedAdsSectionState();
}

class _ProfileLinkedAdsSectionState extends State<_ProfileLinkedAdsSection> {
  List<AdModel> _ads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await AdsRepository().getMyAds(page: 1, perPage: 30);
      if (!mounted) return;
      setState(() {
        _ads = r.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String? _imageUrl(AdModel ad) {
    for (final path in ad.images) {
      if (path.isEmpty) continue;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      final base = AppConstants.storageBaseUrl.endsWith('/')
          ? AppConstants.storageBaseUrl.substring(
              0,
              AppConstants.storageBaseUrl.length - 1,
            )
          : AppConstants.storageBaseUrl;
      var p = path.startsWith('/') ? path.substring(1) : path;
      if (p.startsWith('storage/')) p = p.substring('storage/'.length);
      return '$base/$p';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'الإعلانات المرتبطة بك'),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingIndicator(),
            ),
          )
        else if (_error != null)
          Text(
            _error!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          )
        else if (_ads.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.inputBorderColor),
            ),
            child: Text(
              'لا توجد إعلانات منشورة بعد.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Column(
            children: [
              ...List.generate(
                _ads.length.clamp(0, 5),
                (i) {
                  final shown = _ads.length > 5 ? 5 : _ads.length;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < shown - 1 ? 10 : 0),
                    child: _LinkedAdRowTile(
                      ad: _ads[i],
                      imageUrl: _imageUrl(_ads[i]),
                    ),
                  );
                },
              ),
              if (_ads.length > 5) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider(
                            create: (_) => MyAdsCubit()..loadMyAds(),
                            child: const MyAdsScreen(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'عرض كل الإعلانات (${_ads.length})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _LinkedAdRowTile extends StatelessWidget {
  final AdModel ad;
  final String? imageUrl;

  const _LinkedAdRowTile({required this.ad, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.adDetails,
          arguments: {'adId': ad.id},
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: context.surfaceBg,
                            child: Icon(Icons.directions_car_outlined,
                                color: context.textHint),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: context.surfaceBg,
                            child: Icon(Icons.directions_car_outlined,
                                color: context.textHint),
                          ),
                        )
                      : Container(
                          color: context.surfaceBg,
                          child: Icon(Icons.directions_car_outlined,
                              color: context.textHint),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.priceFormatted} · ${ad.conditionLabel}',
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: context.textSecondary),
            ],
          ),
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
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                    )),
                const SizedBox(height: 4),
                Text(
                  '${_formatPoints(profile.loyaltyPoints)} نقطة',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
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
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 17.5,
                          )),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(
                              color: context.textSecondary,
                              fontSize: 14,
                            )),
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
                fontSize: 17,
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

// ─────────────────────────────────────────────────────────────────────────────
// Address (PUT /profile/address)
// ─────────────────────────────────────────────────────────────────────────────

class _AddressSection extends StatelessWidget {
  final UserProfileModel profile;

  const _AddressSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final gov = profile.governorateName?.trim();
    final addr = profile.address?.trim();
    final summary = [
      if (gov != null && gov.isNotEmpty) gov,
      if (addr != null && addr.isNotEmpty) addr,
    ].join(' — ');
    final display =
        summary.isNotEmpty ? summary : 'اضغط لتحديد المحافظة والعنوان';

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          final cubit = context.read<UserProfileCubit>();
          _showAddressEditDialog(context, profile, cubit);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العنوان',
                      style: AppTextStyles.caption
                          .copyWith(
                            color: context.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      display,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined,
                  size: 18, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddressEditDialog(
  BuildContext context,
  UserProfileModel profile,
  UserProfileCubit cubit,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _AddressEditDialog(
      profile: profile,
      cubit: cubit,
      parentContext: context,
    ),
  );
}

class _AddressEditDialog extends StatefulWidget {
  final UserProfileModel profile;
  final UserProfileCubit cubit;
  final BuildContext parentContext;

  const _AddressEditDialog({
    required this.profile,
    required this.cubit,
    required this.parentContext,
  });

  @override
  State<_AddressEditDialog> createState() => _AddressEditDialogState();
}

class _AddressEditDialogState extends State<_AddressEditDialog> {
  late final TextEditingController _addressController;
  List<GovernorateModel>? _governorates;
  int? _selectedGovernorateId;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.profile.address ?? '');
    _selectedGovernorateId = widget.profile.governorateId;
    _fetchGovernorates();
  }

  Future<void> _fetchGovernorates() async {
    try {
      final list = await CategoryRepository().getGovernorates();
      if (!mounted) return;
      setState(() {
        _governorates = list;
        _loading = false;
        if (_selectedGovernorateId != null &&
            !list.any((g) => g.id == _selectedGovernorateId)) {
          _selectedGovernorateId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final gid = _selectedGovernorateId;
    final text = _addressController.text.trim();
    if (gid == null || gid <= 0) {
      CustomToast.showError(widget.parentContext, 'اختر المحافظة');
      return;
    }
    if (text.isEmpty) {
      CustomToast.showError(widget.parentContext, 'أدخل العنوان التفصيلي');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.cubit.updateProfileAddress(
        governorateId: gid,
        address: text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        CustomToast.showSuccess(
          widget.parentContext,
          'تم تحديث العنوان بنجاح',
        );
      }
    } catch (e) {
      if (widget.parentContext.mounted) {
        CustomToast.showError(
          widget.parentContext,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('تعديل العنوان', style: AppTextStyles.headingSmall),
      content: SingleChildScrollView(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: LoadingIndicator()),
              )
            : _loadError != null
                ? Text(
                    _loadError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'المحافظة',
                        style: AppTextStyles.caption
                            .copyWith(color: context.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedGovernorateId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.inputBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.inputBorderColor),
                          ),
                        ),
                        items: _governorates!
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _selectedGovernorateId = v),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'العنوان التفصيلي',
                        style: AppTextStyles.caption
                            .copyWith(color: context.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        maxLines: 3,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          hintText: 'الشارع، الحي، أقرب معلم…',
                          filled: true,
                          fillColor: context.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.inputBorderColor),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'إلغاء',
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondary),
          ),
        ),
        TextButton(
          onPressed: (_loading || _loadError != null || _saving)
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'حفظ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
