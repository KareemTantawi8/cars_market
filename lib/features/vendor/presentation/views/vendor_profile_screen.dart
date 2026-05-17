import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/vendor_profile_cubit.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../home/data/repositories/search_requests_repository.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../../home/data/models/category_models.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../ads/data/repositories/ads_repository.dart';
import '../../../ads/data/models/ad_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vendor / Customer Profile Visit Screen
// ─────────────────────────────────────────────────────────────────────────────

class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  final String? vendorName;

  /// When true, [vendorId] is parsed as **user** id (e.g. from ad seller).
  final bool bySellerUserId;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
    this.vendorName,
    this.bySellerUserId = false,
  });

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(vendorId) ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<VendorProfileCubit, VendorProfileState>(
          builder: (context, state) {
            if (state is VendorProfileLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is VendorProfileError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<VendorProfileCubit>().fetchVendorProfile(
                        parsedId,
                        bySellerUserId: bySellerUserId,
                      ),
                ),
              );
            }
            if (state is VendorProfileLoaded) {
              return _ProfileBody(
                profile: state.profile,
                vendorId: vendorId,
                bySellerUserId: bySellerUserId,
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
// Main scrollable body
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final VendorProfileModel profile;
  final String vendorId;
  final bool bySellerUserId;

  const _ProfileBody({
    required this.profile,
    required this.vendorId,
    required this.bySellerUserId,
  });

  int get _adsUserId {
    final accountId = profile.userAccountId;
    if (accountId != null && accountId > 0) return accountId;
    final requestedId = int.tryParse(vendorId);
    if (bySellerUserId && requestedId != null && requestedId > 0) {
      return requestedId;
    }
    return profile.id;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Gradient hero header ──────────────────────────────────────────────
        SliverToBoxAdapter(child: _ProfileHeroHeader(profile: profile)),

        // ── Body cards ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 34, 16, 40),
                child: profile.isVendorAccount
                    ? _VendorContent(profile: profile, adsUserId: _adsUserId)
                    : _CustomerContent(profile: profile, adsUserId: _adsUserId),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeroHeader extends StatelessWidget {
  final VendorProfileModel profile;

  const _ProfileHeroHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isVendor = profile.isVendorAccount;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVendor
              ? [
                  const Color(0xFF061020),
                  const Color(0xFF0D2040),
                  AppColors.primaryColor,
                ]
              : [
                  const Color(0xFF0D0D1A),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(child: CustomPaint(painter: _HeroPainter())),

          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconButton(
                  icon: Icons.arrow_forward,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // Main content
          Positioned(
            bottom: 44,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Avatar with glow ring
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isVendor
                        ? const LinearGradient(
                            colors: [Colors.white, Color(0xFFADD8FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: isVendor
                        ? null
                        : Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: isVendor
                            ? AppColors.primaryColor.withOpacity(0.55)
                            : Colors.black.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child:
                        profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profile.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _avatarFallback(isVendor),
                            errorWidget: (_, __, ___) =>
                                _avatarFallback(isVendor),
                          )
                        : _avatarFallback(isVendor),
                  ),
                ),
                const SizedBox(height: 14),

                // Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF7DD3FC),
                        size: 24,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Badges row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroBadge(
                      label: isVendor ? 'تاجر' : 'عميل',
                      icon: isVendor
                          ? Icons.storefront_rounded
                          : Icons.person_rounded,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    if (isVendor && profile.isVerified)
                      _HeroBadge(
                        label: 'موثّق',
                        icon: Icons.verified_rounded,
                        color: AppColors.success.withOpacity(0.3),
                        borderColor: AppColors.success.withOpacity(0.7),
                      ),
                    if (isVendor)
                      _HeroBadge(
                        label: profile.isOpen ? 'أونلاين' : 'مغلق',
                        icon: Icons.circle,
                        color: profile.isOpen
                            ? AppColors.success.withOpacity(0.28)
                            : AppColors.error.withOpacity(0.28),
                        borderColor: profile.isOpen
                            ? AppColors.success.withOpacity(0.65)
                            : AppColors.error.withOpacity(0.65),
                        iconSize: 9,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(bool isVendor) {
    return Container(
      color: AppColors.primaryDark,
      child: Icon(
        isVendor ? Icons.storefront_rounded : Icons.person_rounded,
        size: 44,
        color: Colors.white70,
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? borderColor;
  final double iconSize;

  const _HeroBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.borderColor,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vendor Content
// ─────────────────────────────────────────────────────────────────────────────

class _VendorContent extends StatelessWidget {
  final VendorProfileModel profile;
  final int adsUserId;

  const _VendorContent({required this.profile, required this.adsUserId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats row ─────────────────────────────────────────────────────────
        _VendorStatsRow(profile: profile),
        const SizedBox(height: 20),

        // ── Detailed info ─────────────────────────────────────────────────────
        _SectionCard(
          title: 'تفاصيل التاجر',
          icon: Icons.info_outline_rounded,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'الاسم',
                value: profile.name,
              ),
              _DetailDivider(),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'رقم التواصل',
                value: _displayPhone(profile) ?? 'غير متوفر',
                isLtr: true,
              ),
              _DetailDivider(),
              _DetailRow(
                icon: Icons.star_outline_rounded,
                label: 'التقييم',
                value:
                    '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount} تقييم)',
                valueColor: AppColors.ratingStar,
                trailing: _StarsMini(rating: profile.rating),
              ),
              if (profile.address != null && profile.address!.trim().isNotEmpty) ...[
                _DetailDivider(),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'العنوان',
                  value: _displayAddress(profile),
                ),
              ],
              _DetailDivider(),
              _DetailRow(
                icon: Icons.speed_rounded,
                label: 'سرعة الرد',
                value: _displayResponseSpeed(profile),
                valueColor: AppColors.primaryColor,
              ),
              _DetailDivider(),
              _DetailRow(
                icon: Icons.verified_outlined,
                label: 'الحساب',
                value: profile.isVerified ? 'موثّق ✓' : 'غير موثّق',
                valueColor: profile.isVerified ? AppColors.success : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Brands ───────────────────────────────────────────────────────────
        if (profile.supportedBrands
            .where((b) => b.trim().isNotEmpty)
            .isNotEmpty) ...[
          _SectionCard(
            title: 'الماركات المدعومة',
            icon: Icons.directions_car_outlined,
            child: _BrandsGrid(
              brands: profile.supportedBrands
                  .where((b) => b.trim().isNotEmpty)
                  .toList(),
              supportedBrandIds: profile.supportedBrandIds,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Services ─────────────────────────────────────────────────────────
        if (profile.availableServices.isNotEmpty) ...[
          _SectionCard(
            title: 'الخدمات المتوفرة',
            icon: Icons.build_outlined,
            child: _ServicesChips(services: profile.availableServices),
          ),
          const SizedBox(height: 16),
        ],

        // ── Address map card ─────────────────────────────────────────────────
        if (profile.address != null && profile.address!.trim().isNotEmpty) ...[
          _AddressCard(profile: profile),
          const SizedBox(height: 16),
        ],

        // ── Action buttons ───────────────────────────────────────────────────
        _VendorActionButtons(profile: profile),
        const SizedBox(height: 20),

        // ── Related ads ──────────────────────────────────────────────────────
        _SectionTitle(title: 'إعلانات التاجر', icon: Icons.campaign_outlined),
        const SizedBox(height: 12),
        _UserPublicAdsSection(userId: adsUserId),
        const SizedBox(height: 16),
      ],
    );
  }

  String? _displayPhone(VendorProfileModel p) {
    final phone = p.shopPhone?.trim().isNotEmpty == true
        ? p.shopPhone
        : p.phone;
    return phone?.trim().isEmpty == true ? null : phone?.trim();
  }

  String _displayAddress(VendorProfileModel p) {
    final address = p.address?.trim();
    return (address != null && address.isNotEmpty) ? address : 'غير متوفر';
  }

  String _displayResponseSpeed(VendorProfileModel p) {
    final human = p.responseTimeHuman?.trim();
    if (human != null && human.isNotEmpty) return human;
    final minutes = p.responseTimeMinutes;
    if (minutes != null && minutes > 0) return '$minutes دقيقة';
    return 'غير متوفر';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer Content
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerContent extends StatelessWidget {
  final VendorProfileModel profile;
  final int adsUserId;

  const _CustomerContent({required this.profile, required this.adsUserId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Details card ──────────────────────────────────────────────────────
        _SectionCard(
          title: 'بيانات العميل',
          icon: Icons.person_outline_rounded,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'الاسم',
                value: profile.name,
              ),
              _DetailDivider(),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                value: _displayPhone(profile) ?? 'غير متوفر',
                isLtr: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Action buttons ───────────────────────────────────────────────────
        _CustomerActionButtons(profile: profile),
        const SizedBox(height: 20),

        // ── Related ads ──────────────────────────────────────────────────────
        _SectionTitle(title: 'إعلانات العميل', icon: Icons.campaign_outlined),
        const SizedBox(height: 12),
        _UserPublicAdsSection(userId: adsUserId),
        const SizedBox(height: 16),
      ],
    );
  }

  String? _displayPhone(VendorProfileModel p) {
    final phone = p.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vendor Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _VendorStatsRow extends StatelessWidget {
  final VendorProfileModel profile;

  const _VendorStatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            value: profile.rating.toStringAsFixed(1),
            label: '${profile.ratingCount} تقييم',
            color: AppColors.ratingStar,
          ),
        ),
        const SizedBox(width: 10),
        if (profile.responseTimeMinutes != null ||
            profile.responseTimeHuman != null) ...[
          Expanded(
            child: _StatCard(
              icon: Icons.speed_rounded,
              value: _responseValue(profile),
              label: 'سرعة الرد',
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _StatCard(
            icon: profile.isOpen
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            value: profile.isOpen ? 'أونلاين' : 'مغلق',
            label: profile.openUntil ?? '',
            color: profile.isOpen ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    ));
  }

  String _responseValue(VendorProfileModel p) {
    final human = p.responseTimeHuman?.trim();
    if (human != null && human.isNotEmpty) return human;
    final m = p.responseTimeMinutes;
    if (m != null && m > 0) return '$m د';
    return '—';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.22), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.primaryColor.withOpacity(0.03),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.primaryColor.withOpacity(0.15)),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLtr;
  final Color? valueColor;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLtr = false,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
              textAlign: TextAlign.start,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? context.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.inputBorderColor.withOpacity(0.4));
  }
}

// Mini star display
class _StarsMini extends StatelessWidget {
  final double rating;

  const _StarsMini({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData iconData;
        if (i < full) {
          iconData = Icons.star_rounded;
        } else if (i == full && half) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_outline_rounded;
        }
        return Icon(iconData, size: 16, color: AppColors.ratingStar);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brands chips
// ─────────────────────────────────────────────────────────────────────────────

class _BrandsGrid extends StatelessWidget {
  final List<String> brands;
  final List<int> supportedBrandIds;

  const _BrandsGrid({
    required this.brands,
    this.supportedBrandIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BrandModel>>(
      future: CategoryRepository().getBrands(),
      builder: (context, snapshot) {
        final allBrands = snapshot.data ?? const <BrandModel>[];
        final tiles = brands.map((brandName) {
          final matchedById = allBrands.where(
            (b) => supportedBrandIds.contains(b.id),
          );
          final byId = matchedById.isNotEmpty
              ? matchedById.firstWhere(
                  (b) =>
                      b.displayName.trim().toLowerCase() ==
                      brandName.trim().toLowerCase(),
                  orElse: () => matchedById.first,
                )
              : null;
          final byName = allBrands.where((b) {
            final n = b.name.trim().toLowerCase();
            final na = (b.nameAr ?? '').trim().toLowerCase();
            final target = brandName.trim().toLowerCase();
            return n == target || na == target;
          });
          final match = byId ?? (byName.isNotEmpty ? byName.first : null);

          return _BrandImageTile(
            name: brandName,
            logoUrl: _normalizeBrandLogo(match?.logo),
          );
        }).toList();

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tiles,
        );
      },
    );
  }

  String? _normalizeBrandLogo(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final logo = raw.trim();
    if (logo.startsWith('http://') || logo.startsWith('https://')) return logo;
    final base = AppConstants.storageBaseUrl.endsWith('/')
        ? AppConstants.storageBaseUrl.substring(0, AppConstants.storageBaseUrl.length - 1)
        : AppConstants.storageBaseUrl;
    final path = logo.startsWith('/') ? logo.substring(1) : logo;
    return '$base/$path';
  }
}

class _BrandImageTile extends StatelessWidget {
  final String name;
  final String? logoUrl;

  const _BrandImageTile({required this.name, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: context.inputBorderColor.withOpacity(0.8)),
            ),
            child: ClipOval(
              child: logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _fallback(context),
                      errorWidget: (_, __, ___) => _fallback(context),
                    )
                  : _fallback(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.caption.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: context.surfaceBg,
      child: Icon(
        Icons.directions_car_rounded,
        color: AppColors.primaryColor,
        size: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services chips
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesChips extends StatelessWidget {
  final List<String> services;

  const _ServicesChips({required this.services});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: services
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.inputBorderColor, width: 1.2),
              ),
              child: Text(
                s,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address card
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final VendorProfileModel profile;

  const _AddressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.address != null && profile.address!.isNotEmpty)
                  Text(
                    profile.address!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (profile.latitude != null && profile.longitude != null)
            GestureDetector(
              onTap: () => _openMaps(profile),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'الاتجاهات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaps(VendorProfileModel p) async {
    final lat = p.latitude;
    final lng = p.longitude;
    if (lat == null || lng == null) return;

    final candidates = <Uri>[];
    if (Platform.isAndroid) {
      candidates.add(Uri.parse('google.navigation:q=$lat,$lng&mode=d'));
      candidates.add(Uri.parse('geo:$lat,$lng?q=$lat,$lng'));
    } else if (Platform.isIOS) {
      candidates.add(
        Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'),
      );
      candidates.add(Uri.parse('maps://?daddr=$lat,$lng&dirflg=d'));
    }
    candidates.add(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
        'travelmode': 'driving',
      }),
    );

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — Vendor
// ─────────────────────────────────────────────────────────────────────────────

class _VendorActionButtons extends StatelessWidget {
  final VendorProfileModel profile;

  const _VendorActionButtons({required this.profile});

  @override
  Widget build(BuildContext context) {
    final userType = StorageService.getUserType();
    final isCustomer = userType != AppConstants.userTypeVendor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'التواصل مع التاجر',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCustomer) ...[
            _ActionButton(
              label: 'بدء محادثة',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryColor,
              onTap: () => _startChat(context),
            ),
            const SizedBox(height: 10),
          ],
          _ActionButton(
            label: 'واتساب',
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.success,
            onTap: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
          ),
          if (isCustomer) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(context),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: Text(
                  'تقييم التاجر',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.ratingStar,
                  side: BorderSide(
                    color: AppColors.ratingStar.withOpacity(0.75),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final otherUserId = profile.userAccountId;
    if (otherUserId == null || otherUserId <= 0) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'لا يمكن تحديد حساب هذا التاجر. جرّب واتساب.',
        );
      }
      return;
    }
    try {
      final chatId = await ChatRepository().openChatWithAdSeller(
        sellerUserId: otherUserId,
        sellerVendorRecordId: profile.id,
      );
      if (!context.mounted) return;
      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': profile.name,
            'peerPhone': profile.phone ?? profile.shopPhone,
            'peerIsVerified': profile.isVerified,
            'peerAvatarUrl': profile.imageUrl,
          },
        );
      } else {
        CustomToast.showError(
          context,
          'لا يمكن بدء المحادثة الآن. جرّب واتساب أو أعد المحاولة لاحقاً.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'تعذّر فتح المحادثة. ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    String clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!clean.startsWith('20')) clean = '20$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    List<Map<String, dynamic>> requests;
    try {
      requests = await SearchRequestsRepository().getMySearchRequests();
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(context, 'تعذّر تحميل الطلبات، حاول مرة أخرى.');
      }
      return;
    }

    final target = requests.firstWhere((r) {
      final status = r['status'] as String?;
      final hasRating = r['rating'] != null;
      final vid =
          (r['vendor'] as Map?)?['id'] ?? (r['accepted_by'] as Map?)?['id'];
      final vId = vid is num
          ? vid.toInt()
          : int.tryParse(vid?.toString() ?? '');
      return (status == 'accepted' || status == 'completed') &&
          !hasRating &&
          vId == profile.id;
    }, orElse: () => {});

    if (target.isEmpty) {
      if (context.mounted) {
        CustomToast.showInfo(
          context,
          'لا توجد طلبات مكتملة مع هذا التاجر للتقييم.',
        );
      }
      return;
    }
    if (!context.mounted) return;

    int selectedRating = 0;
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            'تقييم ${profile.name}',
            style: AppTextStyles.headingSmall,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: AppColors.ratingStar,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقاً (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await SearchRequestsRepository().rateSearchRequest(
                          requestId: target['id'] as int,
                          rating: selectedRating,
                          review: reviewController.text.trim().isEmpty
                              ? null
                              : reviewController.text.trim(),
                        );
                        if (context.mounted) {
                          CustomToast.showSuccess(
                            context,
                            'تم إرسال التقييم بنجاح!',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomToast.showError(
                            context,
                            'تعذّر إرسال التقييم: $e',
                          );
                        }
                      } finally {
                        reviewController.dispose();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — Customer
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerActionButtons extends StatelessWidget {
  final VendorProfileModel profile;

  const _CustomerActionButtons({required this.profile});

  @override
  Widget build(BuildContext context) {
    final myId = int.tryParse(StorageService.getUserId() ?? '');
    final otherId = profile.userAccountId ?? profile.id;
    final canChat = myId != null && otherId > 0 && myId != otherId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'التواصل',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (canChat) ...[
            _ActionButton(
              label: 'بدء محادثة',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryColor,
              onTap: () => _startChat(context),
            ),
            const SizedBox(height: 10),
          ],
          _ActionButton(
            label: 'واتساب',
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.success,
            onTap: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
          ),
        ],
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final otherUserId = profile.userAccountId ?? profile.id;
    if (otherUserId <= 0) {
      if (context.mounted) {
        CustomToast.showError(context, 'لا يمكن تحديد حساب المستخدم للمحادثة.');
      }
      return;
    }
    try {
      final chatId = await ChatRepository().openChatWithUser(otherUserId);
      if (!context.mounted) return;
      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': profile.name,
            'peerPhone': profile.phone,
            'peerIsVerified': profile.isVerified,
            'peerAvatarUrl': profile.imageUrl,
          },
        );
      } else {
        CustomToast.showError(
          context,
          'لا يمكن بدء المحادثة الآن. جرّب واتساب أو أعد المحاولة لاحقاً.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'تعذّر فتح المحادثة. ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    String clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!clean.startsWith('20')) clean = '20$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable filled button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 21),
        label: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 22, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Public Ads Section
// ─────────────────────────────────────────────────────────────────────────────

class _UserPublicAdsSection extends StatefulWidget {
  final int userId;

  const _UserPublicAdsSection({required this.userId});

  @override
  State<_UserPublicAdsSection> createState() => _UserPublicAdsSectionState();
}

class _UserPublicAdsSectionState extends State<_UserPublicAdsSection> {
  late final Future<List<AdModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdsRepository().getAdsByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId <= 0) return const SizedBox.shrink();

    return FutureBuilder<List<AdModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: LoadingIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _emptyBox(context, 'تعذّر تحميل الإعلانات.');
        }
        final ads = snapshot.data ?? [];
        if (ads.isEmpty) {
          return _emptyBox(context, 'لا توجد إعلانات لعرضها.');
        }
        return Column(
          children: ads
              .map(
                (ad) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AdTile(ad: ad),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _emptyBox(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AdTile extends StatelessWidget {
  final AdModel ad;

  const _AdTile({required this.ad});

  String? _imageUrl() {
    final path = ad.firstImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConstants.storageBaseUrl.endsWith('/')
        ? AppConstants.storageBaseUrl.substring(
            0,
            AppConstants.storageBaseUrl.length - 1,
          )
        : AppConstants.storageBaseUrl;
    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$sanitized';
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl();

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.adDetails,
          arguments: {'adId': ad.id},
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.inputBorderColor, width: 1.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imgFallback(context),
                          errorWidget: (_, __, ___) => _imgFallback(context),
                        )
                      : _imgFallback(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      ad.priceFormatted,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    if (ad.locationLabel != null &&
                        ad.locationLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ad.locationLabel!.trim(),
                              style: AppTextStyles.caption.copyWith(
                                color: context.textSecondary,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgFallback(BuildContext context) {
    return ColoredBox(
      color: context.surfaceBg,
      child: Icon(
        Icons.directions_car_outlined,
        color: context.textHint,
        size: 32,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero background painter
// ─────────────────────────────────────────────────────────────────────────────

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      size.width * 0.35,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 1.1),
      size.width * 0.4,
      paint..color = Colors.white.withOpacity(0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
