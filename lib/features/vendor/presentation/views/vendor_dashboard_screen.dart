import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../../../shared/widgets/buttons/delete_account_button.dart';
import '../../../../shared/widgets/common/support_link_tile.dart';
import '../../../../shared/widgets/dialogs/vendor_requests_popup.dart';
import '../cubit/vendor_dashboard_cubit.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../data/repositories/vendor_profile_repository.dart';
import 'vendor_location_edit_screen.dart';

/// Vendor Dashboard Screen
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  // Debounce realtime popup only (no auto-popup on dashboard open).
  static DateTime? _lastPopupTime;

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
    RealtimeService.instance.onVendorShowRequestsPopup =
        _onVendorShowRequestsPopup;
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

  void _onVendorShowRequestsPopup(Map<String, dynamic> data) {
    if (!mounted) return;
    // Debounce to prevent multiple popups stacking simultaneously from burst events
    if (_lastPopupTime != null &&
        DateTime.now().difference(_lastPopupTime!).inSeconds < 5) {
      return;
    }
    _lastPopupTime = DateTime.now();
    showVendorRequestsPopup(context);
  }

  void _onVendorNewMessage(Map<String, dynamic> data) {
    InAppNotificationService.showNewMessageReverb(data);
  }

  @override
  void dispose() {
    RealtimeService.instance.onVendorSearchRequestCreated = null;
    RealtimeService.instance.onVendorShowRequestsPopup = null;
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
          scaffoldBackgroundColor: Colors.black,
          brightness: Brightness.dark,
          canvasColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
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
                  color: AppColors.primaryColor,
                  backgroundColor: AppColors.cardColor,
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
          _buildContentSheet(context, profile),
        ],
      ),
    );
  }

  // ─── Flat Header (like customer profile) ─────────────────────────────────

  Widget _buildFlatHeader(BuildContext context, VendorProfileModel profile) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Bell | title | shop toggle — fixed LTR so layout matches design in RTL locales.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: NotificationBell(iconColor: AppColors.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'لوحة التحكم',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48, height: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Avatar — tappable to change photo
            GestureDetector(
              onTap: () => _changeProfileImage(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildFlatAvatar(profile),
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
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
                      size: 22,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.45)),
              ),
              child: Text(
                'تاجر',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (profile.description != null &&
                profile.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  profile.description!.trim(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOnlineStatusCard(context, profile),
            ),
            const SizedBox(height: 20),
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

  /// Full-width online/offline control below profile header.
  Widget _buildOnlineStatusCard(BuildContext context, VendorProfileModel profile) {
    final isOpen = profile.isOpen;
    final statusColor = isOpen ? AppColors.success : AppColors.error;
    final title = isOpen ? 'المحل مفتوح — متصل' : 'المحل مغلق — غير متصل';
    final subtitle = isOpen
        ? (profile.openUntil != null && profile.openUntil!.isNotEmpty
            ? 'متاح حتى ${profile.openUntil}'
            : 'تستقبل طلبات البحث الآن')
        : 'لن تصلك طلبات بحث جديدة';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleOnlineStatus(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isOpen,
                onChanged: (_) => _toggleOnlineStatus(context),
                activeColor: AppColors.success,
                inactiveThumbColor: AppColors.error,
                inactiveTrackColor: AppColors.error.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Content sheet ────────────────────────────────────────────────────────

  Widget _buildContentSheet(BuildContext context, VendorProfileModel profile) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row (description lives in header)
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

            // Messaging
            _buildMessagingCard(context),
            const SizedBox(height: 28),

            // Account
            _buildAccountCard(context),
            _buildDeleteAccountSection(context),
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
    final responseValue = hasResponseTime
        ? (profile.responseTimeMinutes != null
            ? '${profile.responseTimeMinutes}د'
            : (profile.responseTimeHuman ?? '—'))
        : '—';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.star_rounded,
            iconColor: AppColors.ratingStar,
            value: profile.rating.toStringAsFixed(1),
            label: '${profile.ratingCount} تقييم',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.timer_outlined,
            iconColor: AppColors.primaryLight,
            value: responseValue,
            label: 'سرعة الرد',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.storefront_outlined,
            iconColor: profile.isOpen ? AppColors.success : AppColors.error,
            value: profile.isOpen ? 'متصل' : 'غير متصل',
            label: 'الحالة',
            onTap: () => _toggleOnlineStatus(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

  Future<void> _changeProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    // Bottom sheet to pick source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: const Text('اختر من المعرض'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryDark,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text('التقط صورة جديدة'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !context.mounted) return;

    final file = File(picked.path);

    // Show uploading indicator
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('جاري رفع الصورة...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final repo = UserProfileRepository();
      await repo.uploadProfileImages(profileImage: file);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      CustomToast.showSuccess(context, 'تم تحديث صورة الملف الشخصي');
      await context.read<VendorDashboardCubit>().refresh();
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      CustomToast.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
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
          _buildBrandsRow(profile.supportedBrandsData.isNotEmpty
              ? profile.supportedBrandsData
              : brands.map((b) => {'name': b, 'imageUrl': ''}).toList()),
      ],
    );
  }

  Widget _buildBrandsRow(List<Map<String, String>> brands) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final brand = brands[i];
          final name = brand['name'] ?? '';
          final imageUrl = brand['imageUrl'] ?? '';
          final hasImage = imageUrl.isNotEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.directions_car_outlined,
                            color: AppColors.primaryColor,
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.directions_car_outlined,
                          color: AppColors.primaryColor,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 68,
                child: Text(
                  name,
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

                    // Edit location — bottom center
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

                    // Use current GPS — top-left (separate from edit CTA)
                    Positioned(
                      top: 52,
                      left: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => unawaited(
                            _performSetLocation(context, profile),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'موقع الجهاز',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorLocationEditScreen(profile: profile),
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

  Future<void> _showEditAddressDialog(
    BuildContext context,
    VendorProfileModel profile,
  ) async {
    final saved = await Navigator.of(context).pushNamed(
      AppRoutes.vendorLocationEdit,
      arguments: profile,
    );
    if (saved == true && context.mounted) {
      await context.read<VendorDashboardCubit>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث العنوان بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
          const SupportLinkTile(embeddedInAccountCard: true),
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
            onTap: () async => NavigationService.navigateToLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSection(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: DeleteAccountButton(),
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


// ─── Set Location Dialog ────────────────────────────────────────────────────

class _SetLocationDialog extends StatelessWidget {
  final VoidCallback onSetLocation;
  final VoidCallback onCancel;

  const _SetLocationDialog({
    required this.onSetLocation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'تحديد موقع المحل',
              style: AppTextStyles.headingSmall.copyWith(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'سيتم استخدام موقعك الحالي كموقع للمحل وسيظهر للعملاء على الخريطة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Set location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSetLocation,
                icon: const Icon(Icons.my_location_rounded, size: 20),
                label: const Text('تحديد موقعي الحالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'إلغاء',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          ],
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
