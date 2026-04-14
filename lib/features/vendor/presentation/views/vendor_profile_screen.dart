import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
import '../../../../shared/widgets/common/custom_toast.dart';

/// Vendor Profile Screen
class VendorProfileScreen extends StatelessWidget {
  final String vendorId;
  final String? vendorName;

  /// When true, [vendorId] is parsed as **user** id (e.g. from ad seller); profile is resolved via `GET /users/:id`.
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

    return Theme(
      data: AppTheme.lightTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.lightTheme.appBarTheme.systemOverlayStyle ??
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
        child: Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
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
                      context.read<VendorProfileCubit>().fetchVendorProfile(
                            parsedId,
                            bySellerUserId: bySellerUserId,
                          );
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
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, VendorProfileModel profile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: context.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
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
                // Shop phone (if different from account phone)
                if (profile.shopPhone != null &&
                    profile.shopPhone!.isNotEmpty) ...[
                  _buildShopPhoneRow(context, profile.shopPhone!),
                  const SizedBox(height: 16),
                ],
                // Action Buttons (WhatsApp only)
                _buildActionButtons(context, profile),
                const SizedBox(height: 24),
                // Location Section - only show if profile has actual location data and show as text only
                if (profile.address != null && profile.address!.isNotEmpty)
                  _buildTextAddressSection(context, profile),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorInfoCard(BuildContext context, VendorProfileModel profile) {
    // Flat layout: same background as scaffold (like customer profile / create ad).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular avatar
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: context.surfaceBg,
              backgroundImage: profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(profile.imageUrl!)
                  : null,
              child: profile.imageUrl == null || profile.imageUrl!.isEmpty
                  ? Icon(Icons.storefront, size: 42, color: AppColors.primaryColor)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
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
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Text(
        serviceName,
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildShopPhoneRow(BuildContext context, String shopPhone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم المحل',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondary),
                ),
                Text(
                  shopPhone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:$shopPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'اتصال',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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
              onPressed: () => _openChatWithVendor(context, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
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
                foregroundColor: Colors.white,
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
          const SizedBox(height: 12),
          // Rate Vendor Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRatingDialog(context, profile),
              icon: const Icon(Icons.star_outline, size: 20),
              label: const Text(
                'تقييم التاجر',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ratingStar,
                side: const BorderSide(color: AppColors.ratingStar),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          foregroundColor: Colors.white,
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

  Widget _buildTextAddressSection(BuildContext context, VendorProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('العنوان', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.governorate != null && profile.governorate!.isNotEmpty)
                      Text(profile.governorate!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    if (profile.address != null && profile.address!.isNotEmpty)
                      Text(profile.address!, style: AppTextStyles.bodySmall.copyWith(color: context.textSecondary)),
                  ],
                ),
              ),
              if (profile.latitude != null && profile.longitude != null)
                GestureDetector(
                  onTap: () => _openGoogleMaps(profile.latitude, profile.longitude, profile.address),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('الاتجاهات', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openChatWithVendor(
      BuildContext context, VendorProfileModel profile) async {
    final otherUserId = profile.userAccountId;
    if (otherUserId == null || otherUserId <= 0) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'لا يمكن تحديد حساب هذا التاجر للمحادثة. يمكنك التواصل عبر واتساب.',
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
    if (lat == null && lng == null && (address == null || address.isEmpty)) return;

    // Try native app URI first (opens Maps directly in directions mode),
    // then fall back to universal web URL.
    final List<Uri> candidates = [];

    if (lat != null && lng != null) {
      if (Platform.isAndroid) {
        // geo: intent opens any maps app; google.navigation forces Google Maps + directions
        candidates.add(Uri.parse('google.navigation:q=$lat,$lng&mode=d'));
        candidates.add(Uri.parse('geo:$lat,$lng?q=$lat,$lng'));
      } else if (Platform.isIOS) {
        candidates.add(Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'));
        // Apple Maps fallback
        candidates.add(Uri.parse('maps://?daddr=$lat,$lng&dirflg=d'));
      }
      // Universal web fallback (always last)
      candidates.add(Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lng',
        'travelmode': 'driving',
      }));
    } else if (address != null && address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      if (Platform.isAndroid) {
        candidates.add(Uri.parse('google.navigation:q=$encoded&mode=d'));
      } else if (Platform.isIOS) {
        candidates.add(Uri.parse('comgooglemaps://?daddr=$encoded&directionsmode=driving'));
        candidates.add(Uri.parse('maps://?daddr=$encoded&dirflg=d'));
      }
      candidates.add(Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': address,
        'travelmode': 'driving',
      }));
    }

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  Future<void> _showRatingDialog(
      BuildContext context, VendorProfileModel profile) async {
    // Fetch customer's search requests, find one for this vendor
    List<Map<String, dynamic>> requests;
    try {
      requests = await SearchRequestsRepository().getMySearchRequests();
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(context, 'تعذّر تحميل الطلبات، حاول مرة أخرى.');
      }
      return;
    }

    // Find accepted/unrated request for this vendor
    final target = requests.firstWhere(
      (r) {
        final status = r['status'] as String?;
        final hasRating = r['rating'] != null;
        final vendorId = (r['vendor'] as Map?)?['id'] ??
            (r['accepted_by'] as Map?)?['id'];
        final vendorUserId = vendorId is num ? vendorId.toInt() : int.tryParse(vendorId?.toString() ?? '');
        return (status == 'accepted' || status == 'completed') &&
            !hasRating &&
            vendorUserId == profile.id;
      },
      orElse: () => {},
    );

    if (target.isEmpty) {
      if (context.mounted) {
        CustomToast.showInfo(
            context, 'لا توجد طلبات مكتملة مع هذا التاجر للتقييم.');
      }
      return;
    }

    if (!context.mounted) return;

    int selectedRating = 0;
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('تقييم ${profile.name}',
              style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= selectedRating
                            ? Icons.star
                            : Icons.star_border,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
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
                              context, 'تم إرسال التقييم بنجاح!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomToast.showError(
                              context, 'تعذّر إرسال التقييم: $e');
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
