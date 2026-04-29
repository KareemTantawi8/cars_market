import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../home/data/repositories/category_repository.dart';
import '../../../home/data/models/category_models.dart';
import '../../../ads/presentation/cubit/ads_list_cubit.dart';
import '../../../browse_ads/presentation/views/browse_ads_screen.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../../../../shared/widgets/common/notification_bell.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/vendor_dashboard_cubit.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../data/repositories/vendor_profile_repository.dart';

/// Vendor Dashboard Screen
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVendorRealtime();
    });
  }

  void _startVendorRealtime() {
    if (StorageService.getUserType() != AppConstants.userTypeVendor) return;
    RealtimeService.instance.onVendorSearchRequestCreated =
        _onVendorSearchRequestCreated;
    RealtimeService.instance.onVendorNewMessage = _onVendorNewMessage;
    unawaited(RealtimeService.instance.start());
    unawaited(
      PushNotificationService.instance
          .syncMissedNotificationsFromApiOnResume(),
    );
  }

  void _onVendorSearchRequestCreated(Map<String, dynamic> data) {
    unawaited(InAppNotificationService.showVendorNewSearchRequest(data));
  }

  void _onVendorNewMessage(Map<String, dynamic> data) {
    InAppNotificationService.showNewMessageReverb(data);
  }

  @override
  void dispose() {
    RealtimeService.instance.onVendorSearchRequestCreated = null;
    RealtimeService.instance.onVendorNewMessage = null;
    super.dispose();
  }

  Future<void> _openManageSupportedBrands(
    BuildContext context,
    List<int> initialIds,
  ) async {
    final saved = await Navigator.pushNamed(
      context,
      AppRoutes.vendorSupportedBrands,
      arguments: {'initialBrandIds': initialIds},
    );
    if (!context.mounted) return;
    if (saved == true) {
      await context.read<VendorDashboardCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VendorDashboardCubit()..fetchVendorProfile(),
      child: Theme(
        data: Theme.of(context).copyWith(
          snackBarTheme: Theme.of(context).snackBarTheme.copyWith(
            behavior: SnackBarBehavior.fixed,
          ),
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocBuilder<VendorDashboardCubit, VendorDashboardState>(
          builder: (context, state) {
            if (state is VendorDashboardLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is VendorDashboardError) {
              return Center(
                child: ErrorState(
                  message: state.message,
                  onRetry: () {
                    context.read<VendorDashboardCubit>().fetchVendorProfile();
                  },
                ),
              );
            }
            if (state is VendorDashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<VendorDashboardCubit>().refresh(),
                child: _buildDashboard(context, state.profile),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, VendorProfileModel profile) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildFlatHeader(context, profile),
          Transform.translate(
            offset: const Offset(0, -32),
            child: _buildContentSheet(context, profile),
          ),
        ],
      ),
    );
  }

  // ─── Flat Header (like customer profile) ─────────────────────────────────

  Widget _buildFlatHeader(BuildContext context, VendorProfileModel profile) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar — centered title; online pill (start) + notifications (end)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _buildHeaderOnlinePill(context, profile),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: NotificationBell(iconColor: context.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'لوحة التحكم',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Avatar
            _buildFlatAvatar(profile),
            const SizedBox(height: 16),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
              ),
              child: Text(
                'تاجر',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatAvatar(VendorProfileModel profile) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profile.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.primaryDark,
                  child: const Icon(Icons.storefront, size: 52, color: Colors.white70),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primaryDark,
                  child: const Icon(Icons.storefront, size: 52, color: Colors.white70),
                ),
              )
            : Container(
                color: AppColors.primaryDark,
                child: const Icon(Icons.storefront, size: 52, color: Colors.white70),
              ),
      ),
    );
  }

  /// Compact pill in the app bar (tap toggles online search visibility).
  Widget _buildHeaderOnlinePill(BuildContext context, VendorProfileModel profile) {
    final isOpen = profile.isOpen;
    final accent = isOpen ? AppColors.success : AppColors.error;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleOnlineStatus(context),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withOpacity(0.85), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Text(
                  isOpen ? 'متصل' : 'غير متصل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Content sheet ────────────────────────────────────────────────────────

  Widget _buildContentSheet(BuildContext context, VendorProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            if (profile.description != null &&
                profile.description!.isNotEmpty) ...[
              Text(
                profile.description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.6,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Stats row
            _buildStatsRow(context, profile),
            const SizedBox(height: 28),

            // Brands — always visible so vendor knows where to manage them
            _buildBrandsSectionWithManage(context, profile),
            const SizedBox(height: 28),

            // Services
            if (profile.availableServices.isNotEmpty) ...[
              _buildSectionHeader('الخدمات المتوفرة'),
              const SizedBox(height: 14),
              _buildServiceChips(profile.availableServices),
              const SizedBox(height: 28),
            ],

            // Location
            _buildSectionHeader('الموقع والتواصل'),
            const SizedBox(height: 14),
            _buildLocationCard(context, profile),
            const SizedBox(height: 28),

            // Performance
            _buildPerformanceCard(context, profile),
            const SizedBox(height: 16),

            // Messaging
            _buildMessagingCard(context),
            const SizedBox(height: 28),

            // Account
            _buildAccountCard(context),
          ],
        ),
      ),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, VendorProfileModel profile) {
    final hasResponseTime =
        profile.responseTimeMinutes != null ||
        (profile.responseTimeHuman != null &&
            profile.responseTimeHuman!.isNotEmpty);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.ratingStar,
            value: profile.rating.toStringAsFixed(1),
            label: '${profile.ratingCount} تقييم',
          ),
        ),
        const SizedBox(width: 12),
        if (hasResponseTime) ...[
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_outlined,
              iconColor: AppColors.primaryLight,
              value: profile.responseTimeMinutes != null
                  ? '${profile.responseTimeMinutes}د'
                  : (profile.responseTimeHuman ?? '—'),
              label: 'سرعة الرد',
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildStatCard(
            icon: Icons.storefront_outlined,
            iconColor: profile.isOpen ? AppColors.success : AppColors.error,
            value: profile.isOpen ? 'متصل' : 'غير متصل',
            label: 'الحالة',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.textSecondary,
              fontSize: 14.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }
    return card;
  }

  Future<void> _toggleOnlineStatus(BuildContext context) async {
    try {
      await context.read<VendorDashboardCubit>().toggleOnline();
      if (!context.mounted) return;
      final state = context.read<VendorDashboardCubit>().state;
      final isNowOnline =
          state is VendorDashboardLoaded && state.profile.isOpen;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowOnline
                ? 'أنت الآن متصل وتستلم طلبات البحث'
                : 'أنت الآن غير متصل',
          ),
          backgroundColor: isNowOnline ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─── Section header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            color: context.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ─── Brands ───────────────────────────────────────────────────────────────

  Widget _buildBrandsSectionWithManage(
    BuildContext context,
    VendorProfileModel profile,
  ) {
    final brands = profile.supportedBrands;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionHeader('ماركاتي')),
            GestureDetector(
              onTap: () => _openManageSupportedBrands(
                context,
                profile.supportedBrandIds,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تعديل',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 15,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الإشعارات ستصلك فقط للطلبات المتعلقة بماركاتك',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (brands.isEmpty)
          Row(
            children: [
              // Profile button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.inputBorderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الملف الشخصي',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add brand button
              Expanded(
                child: GestureDetector(
                  onTap: () => _openManageSupportedBrands(
                    context,
                    profile.supportedBrandIds,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'إضافة ماركة',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          _buildBrandsRow(brands),
      ],
    );
  }

  Widget _buildBrandsRow(List<String> brands) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: AppColors.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 64,
                child: Text(
                  brands[i],
                  style: AppTextStyles.caption.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Services ─────────────────────────────────────────────────────────────

  Widget _buildServiceChips(List<String> services) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: services.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Text(
            s,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Location & Contact ───────────────────────────────────────────────────

  Widget _buildLocationCard(BuildContext context, VendorProfileModel profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Map preview ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openGoogleMaps(
              profile.googleMapsUrl,
              profile.latitude,
              profile.longitude,
              profile.address,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Map grid background
                    CustomPaint(painter: _MapGridPainter(isDark: isDark)),

                    // Bottom fade so content bleeds naturally
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              context.cardBg.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tap-to-open label at top-right
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => _openGoogleMaps(
                          profile.googleMapsUrl,
                          profile.latitude,
                          profile.longitude,
                          profile.address,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'فتح الخريطة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Set Address button - prominent CTA
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _showVendorLocationForm(context, profile),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'تعديل الموقع',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Central pin
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulse ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.25,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Pin shadow dot
                          Container(
                            width: 12,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Address row ────────────────────────────────────────────────
          if (profile.address != null || profile.governorate != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      color: AppColors.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile.governorate != null)
                          Text(
                            profile.governorate!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        if (profile.address != null &&
                            profile.address!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            profile.address!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.textSecondary,
                              height: 1.4,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showVendorLocationForm(context, profile),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow to open maps
                  GestureDetector(
                    onTap: () => _openGoogleMaps(
                      profile.googleMapsUrl,
                      profile.latitude,
                      profile.longitude,
                      profile.address,
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.navigation_outlined,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: context.textSecondary.withOpacity(0.1),
            ),
          ],

          // ── Shop phone ─────────────────────────────────────────────────
          if (profile.shopPhone != null && profile.shopPhone!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم المحل',
                          style: AppTextStyles.caption.copyWith(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          profile.shopPhone!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: context.textSecondary.withOpacity(0.1),
            ),
          ],

          // ── Action buttons ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                // Directions
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions_outlined,
                    label: 'الاتجاهات',
                    color: AppColors.primaryColor,
                    onTap: () => _openGoogleMaps(
                      profile.googleMapsUrl,
                      profile.latitude,
                      profile.longitude,
                      profile.address,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Customer-style sheet: governorate (list picker) + detail address + GPS coords.
  Future<void> _showVendorLocationForm(
    BuildContext context,
    VendorProfileModel profile,
  ) async {
    final rootContext = context;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _VendorLocationFormSheet(
          profile: profile,
          onUseCurrentGps: () {
            Navigator.of(sheetContext).pop();
            unawaited(_performSetLocation(rootContext, profile));
          },
        ),
      ),
    );
    if (saved == true && rootContext.mounted) {
      await rootContext.read<VendorDashboardCubit>().refresh();
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث العنوان بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _performSetLocation(
    BuildContext context,
    VendorProfileModel profile,
  ) async {
    final cubit = context.read<VendorDashboardCubit>();

    // Check & request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب السماح بالوصول إلى الموقع لتحديد موقع المحل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تفعيل خدمة الموقع في إعدادات الجهاز'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show loading
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحديد موقعك...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final repo = VendorProfileRepository();
      await repo.updateVendorLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث موقع المحل بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      await cubit.refresh();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openGoogleMaps(
    String? googleMapsUrl,
    double? lat,
    double? lng,
    String? address,
  ) async {
    if (googleMapsUrl != null && googleMapsUrl.isNotEmpty) {
      final url = Uri.tryParse(googleMapsUrl);
      if (url != null && await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (lat != null && lng != null) {
      final url = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
        'travelmode': 'driving',
      });
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (address != null && address.isNotEmpty) {
      final url = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': address,
        'travelmode': 'driving',
      });
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  // ─── Performance report ───────────────────────────────────────────────────

  Widget _buildPerformanceCard(
    BuildContext context,
    VendorProfileModel profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPerformanceReport(context, profile.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تقرير الأداء',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ملخص الطلبات والتقييمات',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPerformanceReport(
    BuildContext context,
    int vendorId,
  ) async {
    final repo = VendorProfileRepository();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final report = await repo.getVendorPerformanceReport(vendorId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      _showReportDialog(context, report);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> report) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تقرير الأداء'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: report.isEmpty
                ? const Text('لا توجد بيانات في التقرير.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _reportEntriesToList(report),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  List<Widget> _reportEntriesToList(
    Map<String, dynamic> map, {
    String prefix = '',
  }) {
    final list = <Widget>[];
    final labels = <String, String>{
      'total_orders': 'إجمالي الطلبات',
      'accepted_orders': 'الطلبات المقبولة',
      'rejected_orders': 'الطلبات المرفوضة',
      'pending_orders': 'الطلبات المعلقة',
      'response_time_human': 'وقت الاستجابة',
      'average_rating': 'متوسط التقييم',
      'ratings_count': 'عدد التقييمات',
      'search_requests_accepted': 'طلبات البحث المقبولة',
      'search_requests_rejected': 'طلبات البحث المرفوضة',
    };
    for (final e in map.entries) {
      final key = e.key;
      final value = e.value;
      final label = labels[key] ?? _keyToLabel(key);
      if (value is Map<String, dynamic>) {
        list.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        list.addAll(_reportEntriesToList(value, prefix: '$prefix  '));
      } else if (value is List) {
        list.add(const SizedBox(height: 8));
        list.add(
          Text(
            '$label: ${value.length}',
            style: AppTextStyles.bodySmall.copyWith(color: context.textPrimary),
          ),
        );
      } else {
        list.add(const SizedBox(height: 6));
        list.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value?.toString() ?? '—',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return list;
  }

  String _keyToLabel(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z])_([a-z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
  }

  // ─── Messaging card ───────────────────────────────────────────────────────

  Widget _buildMessagingCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.chatList),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرسائل',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تواصل مع العملاء',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Account card ─────────────────────────────────────────────────────────
  // Removed: edit profile, change password, theme toggle (white/dark)
  // Kept: notifications, logout

  Widget _buildAccountCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAccountTile(
            icon: Icons.notifications_outlined,
            iconBg: AppColors.primaryColor.withOpacity(0.1),
            iconColor: AppColors.primaryColor,
            title: 'الإشعارات',
            isFirst: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          Divider(
            height: 1,
            indent: 68,
            color: context.textSecondary.withOpacity(0.1),
          ),
          _buildAccountTile(
            icon: Icons.view_list_outlined,
            iconBg: AppColors.primaryColor.withOpacity(0.08),
            iconColor: AppColors.primaryColor,
            title: 'كل إعلانات العملاء',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => CategoryCubit()),
                      BlocProvider(create: (_) => AdsListCubit()),
                    ],
                    child: const BrowseAdsScreen(),
                  ),
                ),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 68,
            color: context.textSecondary.withOpacity(0.1),
          ),
          _buildAccountTile(
            icon: Icons.logout_rounded,
            iconBg: AppColors.error.withOpacity(0.1),
            iconColor: AppColors.error,
            title: 'تسجيل الخروج',
            titleColor: AppColors.error,
            isLast: true,
            onTap: () => NavigationService.navigateToLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: titleColor ?? context.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: context.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same flow as customer home: tap field → list sheet for governorate; address + save; optional GPS.
class _VendorLocationFormSheet extends StatefulWidget {
  final VendorProfileModel profile;
  final VoidCallback onUseCurrentGps;

  const _VendorLocationFormSheet({
    required this.profile,
    required this.onUseCurrentGps,
  });

  @override
  State<_VendorLocationFormSheet> createState() => _VendorLocationFormSheetState();
}

class _VendorLocationFormSheetState extends State<_VendorLocationFormSheet> {
  final _addressController = TextEditingController();
  final _repo = UserProfileRepository();
  final _categoryRepo = CategoryRepository();
  List<GovernorateModel> _governorates = const [];
  int? _selectedGovernorateId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.profile.address ?? '';
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    try {
      final list = await _categoryRepo.getGovernorates();
      if (!mounted) return;
      final currentGov = (widget.profile.governorate ?? '').trim().toLowerCase();
      int? selected;
      if (currentGov.isNotEmpty) {
        for (final g in list) {
          if (g.displayName.trim().toLowerCase() == currentGov) {
            selected = g.id;
            break;
          }
        }
      }
      setState(() {
        _governorates = list;
        _selectedGovernorateId = selected ?? (list.isNotEmpty ? list.first.id : null);
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

  String _governorateDisplayLabel() {
    final id = _selectedGovernorateId;
    if (id == null || _governorates.isEmpty) return 'اختر المحافظة';
    for (final g in _governorates) {
      if (g.id == id) return g.displayName;
    }
    return 'اختر المحافظة';
  }

  void _openGovernoratePicker() {
    if (_saving || _governorates.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر المحافظة',
                style: AppTextStyles.headingSmall.copyWith(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _governorates.length,
                itemBuilder: (context, index) {
                  final g = _governorates[index];
                  final selected = g.id == _selectedGovernorateId;
                  return ListTile(
                    title: Text(
                      g.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 17,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primaryColor : context.textPrimary,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: AppColors.primaryColor)
                        : null,
                    onTap: () {
                      setState(() => _selectedGovernorateId = g.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernorateField() {
    final label = _governorateDisplayLabel();
    final isPlaceholder =
        _selectedGovernorateId == null || _governorates.isEmpty;
    return InkWell(
      onTap: _saving ? null : _openGovernoratePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.inputBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المحافظة',
                    style: AppTextStyles.inputLabel.copyWith(
                      fontSize: 13,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: isPlaceholder
                        ? AppTextStyles.inputHint.copyWith(fontSize: 16.5)
                        : AppTextStyles.input.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: context.textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final gid = _selectedGovernorateId;
    final address = _addressController.text.trim();
    if (gid == null || gid <= 0) {
      CustomToast.showError(context, 'اختر المحافظة');
      return;
    }
    if (address.isEmpty) {
      CustomToast.showError(context, 'أدخل العنوان التفصيلي');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.updateProfileAddress(governorateId: gid, address: address);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.inputBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'موقع المحل',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: context.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: context.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'اختر المحافظة والعنوان التفصيلي. لتحديث موقع الدبوس على الخريطة استخدم زر الموقع من الجهاز.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.45,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 22),
              if (_loading)
                const SizedBox(
                  height: 160,
                  child: Center(child: LoadingIndicator()),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                )
              else ...[
                _buildGovernorateField(),
                const SizedBox(height: 18),
                Text(
                  'العنوان التفصيلي',
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  enabled: !_saving,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'الشارع، المنطقة، أقرب معلم...',
                    hintStyle: AppTextStyles.inputHint.copyWith(fontSize: 16),
                    filled: true,
                    fillColor: context.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.inputBorderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_loading || _error != null || _saving) ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'حفظ العنوان',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: context.textSecondary.withOpacity(0.12)),
                const SizedBox(height: 16),
                Text(
                  'الظهور على الخريطة',
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _saving ? null : widget.onUseCurrentGps,
                  icon: const Icon(Icons.my_location_rounded, size: 22),
                  label: Text(
                    'تحديث موقع المحل من موقع الجهاز',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    side: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

// ─── Map grid painter ──────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  final bool isDark;
  const _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Base map background
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = isDark ? const Color(0xFF1C2A3A) : const Color(0xFFE8EDF3),
    );

    // "Block" fill areas — light parks / zones
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF1E3320) : const Color(0xFFD9EDD8);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width * 0.38, size.height),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, 0, size.width * 0.4, size.height * 0.42),
      blockPaint,
    );

    // "Water" patch
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF1A2E45) : const Color(0xFFBDD8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.42,
          size.height * 0.62,
          size.width * 0.22,
          size.height * 0.38,
        ),
        const Radius.circular(6),
      ),
      waterPaint,
    );

    // Road paint
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3E50) : Colors.white
      ..strokeCap = StrokeCap.round;

    // Major horizontal roads
    for (final frac in [0.22, 0.52, 0.78]) {
      roadPaint.strokeWidth = 8;
      canvas.drawLine(
        Offset(0, size.height * frac),
        Offset(size.width, size.height * frac),
        roadPaint,
      );
    }
    // Minor horizontal roads
    roadPaint.strokeWidth = 3.5;
    for (final frac in [0.12, 0.35, 0.65, 0.88]) {
      canvas.drawLine(
        Offset(0, size.height * frac),
        Offset(size.width, size.height * frac),
        roadPaint,
      );
    }

    // Major vertical roads
    roadPaint.strokeWidth = 8;
    for (final frac in [0.28, 0.62]) {
      canvas.drawLine(
        Offset(size.width * frac, 0),
        Offset(size.width * frac, size.height),
        roadPaint,
      );
    }
    // Minor vertical roads
    roadPaint.strokeWidth = 3.5;
    for (final frac in [0.14, 0.45, 0.78]) {
      canvas.drawLine(
        Offset(size.width * frac, 0),
        Offset(size.width * frac, size.height),
        roadPaint,
      );
    }

    // Road center dashes (yellow)
    final dashPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFD700).withOpacity(0.35)
          : const Color(0xFFFFD700).withOpacity(0.5)
      ..strokeWidth = 1.5;
    _drawDashedLine(
      canvas,
      Offset(0, size.height * 0.52),
      Offset(size.width, size.height * 0.52),
      dashPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(size.width * 0.28, 0),
      Offset(size.width * 0.28, size.height),
      dashPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 10.0;
    const gapLength = 8.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (Offset(dx, dy)).distance;
    if (dist == 0) return;
    final steps = (dist / (dashLength + gapLength)).floor();
    final unitX = dx / dist;
    final unitY = dy / dist;
    for (var i = 0; i < steps; i++) {
      final s = i * (dashLength + gapLength);
      final e = s + dashLength;
      canvas.drawLine(
        Offset(start.dx + unitX * s, start.dy + unitY * s),
        Offset(start.dx + unitX * e, start.dy + unitY * e),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.isDark != isDark;
}
