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
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../ads/presentation/cubit/ads_list_cubit.dart';
import '../../../browse_ads/presentation/views/browse_ads_screen.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VendorDashboardCubit()..fetchVendorProfile(),
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
                onRefresh: () =>
                    context.read<VendorDashboardCubit>().refresh(),
                child: _buildDashboard(context, state.profile),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, VendorProfileModel profile) {
    return CustomScrollView(
      slivers: [
        _buildSliverHero(context, profile),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -32),
            child: _buildContentSheet(context, profile),
          ),
        ),
      ],
    );
  }

  // ─── Hero / AppBar ────────────────────────────────────────────────────────

  Widget _buildSliverHero(BuildContext context, VendorProfileModel profile) {
    const fallbackUrl =
        'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800';
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      // Only notification bell — share / settings / favorite removed
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ),
      ],
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            profile.backgroundImageUrl != null &&
                    profile.backgroundImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profile.backgroundImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.primaryDark),
                    errorWidget: (_, __, ___) => _heroBgFallback(fallbackUrl),
                  )
                : _heroBgFallback(fallbackUrl),

            // Gradient overlay — bottom-heavy for text legibility
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),

            // Vendor name + status badge anchored to bottom-left
            Positioned(
              bottom: 52,
              right: 20,
              left: 20,
              child: _buildHeroCaption(profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBgFallback(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.primaryDark),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.primaryDark,
        child: const Icon(Icons.storefront, size: 80, color: Colors.white24),
      ),
    );
  }

  Widget _buildHeroCaption(VendorProfileModel profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: profile.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.storefront,
                  size: 36, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name + verified
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: AppColors.primaryLight, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Open / Closed pill (tappable to toggle)
              _buildStatusPill(context, profile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(BuildContext context, VendorProfileModel profile) {
    final isOpen = profile.isOpen;
    return GestureDetector(
      onTap: () => _toggleOnlineStatus(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.success.withOpacity(0.9)
              : AppColors.error.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isOpen
                  ? (profile.openUntil != null && profile.openUntil!.isNotEmpty
                      ? 'مفتوح حتى ${profile.openUntil}'
                      : 'متصل')
                  : 'غير متصل',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Stats row
            _buildStatsRow(context, profile),
            const SizedBox(height: 28),

            // Brands
            if (profile.supportedBrands.isNotEmpty) ...[
              _buildSectionHeader('الماركات المدعومة'),
              const SizedBox(height: 14),
              _buildBrandsRow(profile.supportedBrands),
              const SizedBox(height: 28),
            ],

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
    final hasResponseTime = profile.responseTimeMinutes != null ||
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
            onTap: () => _toggleOnlineStatus(context),
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
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.textSecondary,
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
            isNowOnline ? 'أنت الآن متصل وتستلم طلبات البحث' : 'أنت الآن غير متصل',
          ),
          backgroundColor: isNowOnline ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
          ),
        ),
      ],
    );
  }

  // ─── Brands ───────────────────────────────────────────────────────────────

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
                      width: 1.5),
                ),
                child: const Icon(Icons.directions_car_outlined,
                    color: AppColors.primaryColor, size: 26),
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
                color: AppColors.primaryColor.withOpacity(0.25), width: 1),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Map grid background
                    CustomPaint(
                      painter: _MapGridPainter(isDark: isDark),
                    ),

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
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  color: Colors.white, size: 13),
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
                            onTap: () => _showSetLocationDialog(context, profile),
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
                                    color: AppColors.primaryColor.withOpacity(0.4),
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
                                    'تحديد الموقع',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
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
                                  color: AppColors.primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.25),
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
                                      color: AppColors.primaryColor
                                          .withOpacity(0.5),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: Colors.white, size: 22),
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
                    child: const Icon(Icons.place_outlined,
                        color: AppColors.primaryColor, size: 22),
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
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                      child: const Icon(Icons.navigation_outlined,
                          color: AppColors.primaryColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: context.textSecondary.withOpacity(0.1)),
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
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSetLocationDialog(
    BuildContext context,
    VendorProfileModel profile,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SetLocationDialog(
        onSetLocation: () async {
          Navigator.of(dialogContext).pop();
          await _performSetLocation(context, profile);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
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
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
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
      final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (address != null && address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  // ─── Performance report ───────────────────────────────────────────────────

  Widget _buildPerformanceCard(
      BuildContext context, VendorProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primaryColor,
          ],
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
                  child: const Icon(Icons.analytics_outlined,
                      color: Colors.white, size: 28),
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
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ملخص الطلبات والتقييمات',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
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
                  child: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPerformanceReport(BuildContext context, int vendorId) async {
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

  List<Widget> _reportEntriesToList(Map<String, dynamic> map,
      {String prefix = ''}) {
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
        list.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
        list.addAll(_reportEntriesToList(value, prefix: '$prefix  '));
      } else if (value is List) {
        list.add(const SizedBox(height: 8));
        list.add(Text(
          '$label: ${value.length}',
          style: AppTextStyles.bodySmall.copyWith(color: context.textPrimary),
        ));
      } else {
        list.add(const SizedBox(height: 6));
        list.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value?.toString() ?? '—',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.textPrimary),
              ),
            ),
          ],
        ));
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
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel
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
      Rect.fromLTWH(
          size.width * 0.6, 0, size.width * 0.4, size.height * 0.42),
      blockPaint,
    );

    // "Water" patch
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF1A2E45) : const Color(0xFFBDD8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.42, size.height * 0.62,
            size.width * 0.22, size.height * 0.38),
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
        canvas, Offset(0, size.height * 0.52),
        Offset(size.width, size.height * 0.52), dashPaint);
    _drawDashedLine(
        canvas, Offset(size.width * 0.28, 0),
        Offset(size.width * 0.28, size.height), dashPaint);
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
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
