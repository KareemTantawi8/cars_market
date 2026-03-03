import 'package:flutter/material.dart';
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

/// Vendor Profile Screen
class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  final String? vendorName;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
    this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    final userId = int.tryParse(vendorId) ?? 0;
    
    return BlocProvider(
      create: (context) => VendorProfileCubit()..fetchVendorProfile(userId),
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
                  onRetry: () {
                    context.read<VendorProfileCubit>().fetchVendorProfile(userId);
                  },
                ),
              );
            }

            if (state is VendorProfileLoaded) {
              return _buildProfileContent(context, state.profile);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, VendorProfileModel profile) {
    return CustomScrollView(
      slivers: [
        // App Bar with Background Image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: context.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.favorite_border, color: context.textPrimary),
              onPressed: () {
                // TODO: Add to favorites
              },
            ),
            IconButton(
              icon: Icon(Icons.share, color: context.textPrimary),
              onPressed: () {
                // TODO: Share vendor
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildBackgroundImage(profile.backgroundImageUrl),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Info Card
                _buildVendorInfoCard(context, profile),
                const SizedBox(height: 24),
                // Supported Brands Section
                if (profile.supportedBrands.isNotEmpty)
                  _buildSupportedBrandsSection(context, profile.supportedBrands),
                if (profile.supportedBrands.isNotEmpty) const SizedBox(height: 24),
                // Available Services Section
                if (profile.availableServices.isNotEmpty)
                  _buildAvailableServicesSection(context, profile.availableServices),
                if (profile.availableServices.isNotEmpty) const SizedBox(height: 24),
                // Action Buttons (WhatsApp only)
                _buildActionButtons(context, profile),
                const SizedBox(height: 24),
                // Location Section
                if (profile.address != null || profile.latitude != null)
                  _buildLocationSection(context, profile),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage(String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.darken,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black.withOpacity(0.8),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildVendorInfoCard(BuildContext context, VendorProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Verification
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              if (profile.isVerified)
                const Icon(
                  Icons.verified,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
            ],
          ),
          if (profile.description != null) ...[
            const SizedBox(height: 8),
            Text(
              profile.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(context,
                  icon: Icons.access_time,
                  value: profile.isOpen ? 'مفتوح' : 'مغلق',
                  subtitle: profile.openUntil ?? '',
                  color: profile.isOpen ? AppColors.success : AppColors.error,
                ),
              ),
              if (profile.responseTimeMinutes != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(context,
                    icon: Icons.speed,
                    value: '${profile.responseTimeMinutes} دقائق',
                    subtitle: 'سرعة الرد',
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(context,
                  icon: Icons.star,
                  value: profile.rating.toStringAsFixed(1),
                  subtitle: '${profile.ratingCount} تقييم',
                  color: AppColors.ratingStar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedBrandsSection(BuildContext context, List<String> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الماركات المدعومة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: brands.take(4).map((brand) {
            final index = brands.indexOf(brand);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < brands.length - 1 ? 12 : 0),
                child: _buildBrandCard(context, brand),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandCard(BuildContext context, String brandName) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, color: AppColors.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            brandName,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServicesSection(BuildContext context, List<String> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخدمات المتوفرة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: services.map((service) => _buildServiceChip(context, service)).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceChip(BuildContext context, String serviceName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        serviceName,
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VendorProfileModel profile) {
    final userType = StorageService.getUserType();
    final isCustomer = userType != AppConstants.userTypeVendor;
    
    if (isCustomer) {
      // For customers: Show both Chat and WhatsApp buttons
      return Column(
        children: [
          // Start Chat Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to chat - if chat doesn't exist, it will be created
                Navigator.pushNamed(
                  context,
                  AppRoutes.chatRoom,
                  arguments: {
                    'chatId': profile.id.toString(),
                    'chatName': profile.name,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: context.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'بدء محادثة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // WhatsApp Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: context.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'واتساب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // For vendors: Only show WhatsApp button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openWhatsApp(profile.whatsapp ?? profile.phone),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: context.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 24),
            const SizedBox(width: 8),
            const Text(
              'واتساب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    }
  }

  Widget _buildLocationSection(BuildContext context, VendorProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الموقع',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        // Map Placeholder (can be replaced with Google Maps widget)
        GestureDetector(
          onTap: () => _openGoogleMaps(profile.latitude, profile.longitude, profile.address),
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
        if (profile.address != null) ...[
          const SizedBox(height: 16),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () => _openGoogleMaps(
                    profile.latitude,
                    profile.longitude,
                    profile.address,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.governorate != null)
                      Text(
                        profile.governorate!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      profile.address!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }

    // Remove any non-digit characters and ensure it starts with country code
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanNumber.startsWith('20')) {
      cleanNumber = '20$cleanNumber';
    }

    final url = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleMaps(double? lat, double? lng, String? address) async {
    if (lat != null && lng != null) {
      // Open Google Maps with coordinates
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (address != null && address.isNotEmpty) {
      // Open Google Maps with address search
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}
