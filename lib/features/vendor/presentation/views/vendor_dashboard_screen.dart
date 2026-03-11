import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/common/error_state.dart';
import '../cubit/vendor_dashboard_cubit.dart';
import '../../data/models/vendor_profile_model.dart';
import '../../data/repositories/vendor_profile_repository.dart';

/// Vendor Dashboard Screen - Displays vendor profile from auth/me
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
                child: _buildProfileViewDesign(context, state.profile),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileViewDesign(
      BuildContext context, VendorProfileModel profile) {
    return CustomScrollView(
      slivers: [
        // Hero Banner with transparent AppBar overlay
        SliverAppBar(
          expandedHeight: 220,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.favorite_border, color: context.textPrimary),
            onPressed: () {
              // TODO: Add to favorites
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: context.textPrimary),
              onPressed: () {
                // TODO: Share vendor profile
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: context.textPrimary),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: context.textPrimary),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'عرض الملف الشخصي',
              style: AppTextStyles.caption.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            background: _buildHeroBanner(profile.backgroundImageUrl),
          ),
        ),
        // Dark blue content card
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.vendorProfileCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor identity
                    _buildVendorIdentity(profile),
                    const SizedBox(height: 20),
                    // Metrics row
                    _buildProfileMetricsRow(profile),
                    const SizedBox(height: 24),
                    // Supported Brands
                    if (profile.supportedBrands.isNotEmpty) ...[
                      _buildSectionTitle('الماركات المدعومة'),
                      const SizedBox(height: 12),
                      _buildSupportedBrands(profile.supportedBrands),
                      const SizedBox(height: 24),
                    ],
                    // Available Services
                    if (profile.availableServices.isNotEmpty) ...[
                      _buildSectionTitle('الخدمات المتوفرة'),
                      const SizedBox(height: 12),
                      _buildAvailableServicesPills(profile.availableServices),
                      const SizedBox(height: 24),
                    ],
                    // Location
                    _buildSectionTitle('الموقع'),
                    const SizedBox(height: 12),
                    _buildLocationSection(profile),
                    const SizedBox(height: 24),
                    // Performance report
                    _buildPerformanceReportCard(profile),
                    const SizedBox(height: 24),
                    // Quick links / Settings
                    _buildProfileSettingsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(String? imageUrl) {
    const fallbackUrl =
        'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800';
    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black87),
                errorWidget: (_, __, ___) => _heroPlaceholder(fallbackUrl),
              )
            : _heroPlaceholder(fallbackUrl),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroPlaceholder(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.black87),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF1B2032),
        child: Icon(
          Icons.storefront,
          size: 80,
          color: context.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildVendorIdentity(VendorProfileModel profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: profile.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.build_circle_outlined,
                  size: 32,
                  color: AppColors.accentColor,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      color: AppColors.primaryColor,
                      size: 22,
                    ),
                  ],
                ],
              ),
              if (profile.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  profile.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryLight.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMetricsRow(VendorProfileModel profile) {
    return Row(
      children: [
        Expanded(
          child: _buildProfileMetricCard(
            value: profile.isOpen ? 'مفتوح' : 'مغلق',
            subtitle: profile.openUntil ?? '',
            color: profile.isOpen ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        if (profile.responseTimeMinutes != null ||
            (profile.responseTimeHuman != null &&
                profile.responseTimeHuman!.isNotEmpty))
          Expanded(
            child: _buildProfileMetricCard(
              value: profile.responseTimeMinutes != null
                  ? '${profile.responseTimeMinutes} دقائق'
                  : (profile.responseTimeHuman ?? ''),
              subtitle: 'سرعة الرد',
              color: AppColors.primaryLight,
            ),
          ),
        if (profile.responseTimeMinutes != null ||
            (profile.responseTimeHuman != null &&
                profile.responseTimeHuman!.isNotEmpty))
          const SizedBox(width: 12),
        Expanded(
          child: _buildProfileMetricCard(
            value: profile.rating.toStringAsFixed(1),
            subtitle: '${profile.ratingCount} تقييم',
            color: AppColors.ratingStar,
            trailing: const Icon(Icons.star, color: AppColors.ratingStar, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMetricCard({
    required String value,
    required String subtitle,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headingSmall.copyWith(
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildSupportedBrands(List<String> brands) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final brand = brands[i];
          return SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.surfaceBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brand,
                  style: AppTextStyles.caption.copyWith(
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableServicesPills(List<String> services) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: services
          .map(
            (s) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryLight.withOpacity(0.3),
                ),
              ),
              child: Text(
                s,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLocationSection(VendorProfileModel profile) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _openGoogleMaps(
            profile.googleMapsUrl,
            profile.latitude,
            profile.longitude,
            profile.address,
          ),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.map,
                    size: 48,
                    color: context.textSecondary,
                  ),
                ),
                if (profile.latitude != null && profile.longitude != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: context.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Contact bar: Phone + Chat
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openPhone(profile.phone ?? profile.whatsapp),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Icon(Icons.phone, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Material(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': profile.id.toString(),
                        'chatName': profile.name,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'بدء محادثة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (profile.address != null ||
            profile.governorate != null ||
            profile.googleMapsUrl != null) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openGoogleMaps(
              profile.googleMapsUrl,
              profile.latitude,
              profile.longitude,
              profile.address,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation,
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
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      if (profile.address != null) ...[
                        if (profile.governorate != null)
                          const SizedBox(height: 4),
                        Text(
                          profile.address!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryLight.withOpacity(0.9),
                          ),
                        ),
                      ],
                      if ((profile.address == null || profile.address!.isEmpty) &&
                          (profile.governorate == null ||
                              profile.governorate!.isEmpty) &&
                          profile.googleMapsUrl != null)
                        Text(
                          'فتح في خرائط جوجل',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openGoogleMaps(
    String? googleMapsUrl,
    double? lat,
    double? lng,
    String? address,
  ) async {
    // Prefer direct URL from auth/me
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

  Widget _buildPerformanceReportCard(VendorProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تقرير الأداء',
            style: AppTextStyles.headingSmall.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'ملخص أداء المتجر والتجاوب مع الطلبات',
            style: AppTextStyles.caption.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPerformanceReport(context, profile.id),
              icon: const Icon(Icons.analytics_outlined, size: 20),
              label: const Text('عرض التقرير'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.primaryLight,
                side: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
              ),
            ),
          ),
        ],
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

  List<Widget> _reportEntriesToList(Map<String, dynamic> map, {String prefix = ''}) {
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
                style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value?.toString() ?? '—',
                style: AppTextStyles.bodySmall.copyWith(color: context.textPrimary),
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

  Widget _buildProfileSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.edit,
            title: 'تعديل الملف الشخصي',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'الإشعارات',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.lock,
            title: 'تغيير كلمة المرور',
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          const Divider(height: 24),
          _buildThemeSettingItem(context),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            titleColor: AppColors.error,
            onTap: () {
              NavigationService.navigateToLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingItem(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = switch (themeCubit.state) {
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
      ThemeMode.system => 'تلقائي',
    };
    return InkWell(
      onTap: () => _showThemePicker(context, themeCubit),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: colorScheme.primary,
            size: 24,
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
                  ),
                ),
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
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                          : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: titleColor ?? context.textPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: titleColor ?? context.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.textSecondary,
          ),
        ],
      ),
    );
  }
}
