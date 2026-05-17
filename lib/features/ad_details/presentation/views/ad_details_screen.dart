import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../data/models/public_ad_details_model.dart';
import '../../../ads/presentation/cubit/ad_details_cubit.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/data/repositories/ads_repository.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../shared/widgets/common/watermarked_network_image.dart';

/// Public Ad Details Screen
class AdDetailsScreen extends StatefulWidget {
  final String? adId;
  final PublicAdDetailsModel? ad;

  const AdDetailsScreen({super.key, this.adId, this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  bool _descriptionExpanded = false;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  bool _sellerProfileTapEnabled(PublicAdDetailsModel ad) {
    if (ad.sellerVendorRecordId != null && ad.sellerVendorRecordId! > 0) {
      return true;
    }
    final sid = ad.sellerId?.trim();
    return sid != null && sid.isNotEmpty && int.tryParse(sid) != null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: true, child: _buildScreen(context));
  }

  Widget _buildScreen(BuildContext context) {
    if (widget.ad != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, null),
        body: _buildContent(widget.ad!),
      );
    }
    return BlocBuilder<AdDetailsCubit, AdDetailsState>(
      builder: (context, state) {
        if (state is AdDetailsLoaded) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, state.ad),
            body: _buildContent(PublicAdDetailsModel.fromAdModel(state.ad)),
          );
        }
        if (state is AdDetailsError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, null),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('رجوع'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context, null),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildContent(PublicAdDetailsModel ad) {
    // Make the whole details content (including image section) scroll as one page.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(ad),
                _buildInfoCard(ad),
                _buildSpecGrid(ad),
                _buildDetailsSection(ad),
                _buildLocationSection(ad),
                _buildSellerSection(ad),
                _buildSimilarAdsSection(ad),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(ad),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AdModel? ad) {
    final currentUserId = StorageService.getUserId();
    final abilities = StorageService.getAbilities();
    final isOwner =
        ad != null &&
        currentUserId != null &&
        ad.userId.toString() == currentUserId;
    final canAdminAds = abilities.contains('ads.update');
    final isPending = ad?.statusNormalized == 'pending';

    final actions = <Widget>[];
    if (ad != null) {
      if (isOwner) {
        actions.addAll([
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: context.textPrimary,
              size: 22,
            ),
            onPressed: () => _navigateToEdit(context, ad),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 22),
            onPressed: () => _confirmDelete(context, ad.id),
          ),
        ]);
      }
      if (canAdminAds && isPending) {
        actions.addAll([
          IconButton(
            icon: Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 22,
            ),
            tooltip: 'موافقة',
            onPressed: () => _approveAd(context, ad.id),
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            tooltip: 'رفض',
            onPressed: () => _rejectAd(context, ad.id),
          ),
        ]);
      }
    }
    return AppBar(
      backgroundColor: context.surfaceBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_forward, color: context.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'تفاصيل الإعلان',
        style: AppTextStyles.caption.copyWith(color: context.textSecondary),
      ),
      titleSpacing: 0,
      actions: actions.isEmpty ? null : actions,
    );
  }

  void _navigateToEdit(BuildContext context, AdModel ad) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editAd,
      arguments: ad,
    );
    if (context.mounted && result == true) {
      context.read<AdDetailsCubit>().loadAd(ad.id);
    }
  }

  void _confirmDelete(BuildContext context, int adId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdsRepository().deleteAd(adId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الإعلان'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحذف: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAd(BuildContext context, int adId) async {
    try {
      await context.read<AdDetailsCubit>().approveAd(adId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت الموافقة على الإعلان'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectAd(BuildContext context, int adId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الإعلان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سبب الرفض (اختياري):'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'مثال: جودة الصور منخفضة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('رفض', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return;
    try {
      await context.read<AdDetailsCubit>().rejectAd(
        adId,
        rejectionReason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض الإعلان'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildImageSection(PublicAdDetailsModel ad) {
    final imageUrls = ad.imageUrls.map((p) {
      if (p.startsWith('http')) return p;
      return '${AppConstants.storageBaseUrl}/$p';
    }).toList();
    final images = imageUrls.isEmpty ? [null] : imageUrls;
    final screenH = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenH * 0.40).clamp(280.0, 440.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: ColoredBox(
                color: context.cardBg,
                child: PageView.builder(
                  controller: _imagePageController,
                  itemCount: images.length,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    final url = images[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      onTap: url != null && imageUrls.isNotEmpty
                          ? () =>
                                _openFullScreenImage(context, imageUrls, index)
                          : null,
                      child: Container(
                        color: context.cardBg,
                        alignment: Alignment.center,
                        child: url != null
                            ? WatermarkedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (images.length > 1) ...[
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Center(
                  child: _overlayIcon(Icons.chevron_right, () {
                    if (_currentImageIndex < images.length - 1) {
                      _imagePageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Center(
                  child: _overlayIcon(Icons.chevron_left, () {
                    if (_currentImageIndex > 0) {
                      _imagePageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }),
                ),
              ),
            ],
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: AppTextStyles.captionSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  void _openFullScreenImage(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenImageViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Icon(
        Icons.directions_car_outlined,
        size: 80,
        color: context.textHint,
      ),
    );
  }

  Widget _buildInfoCard(PublicAdDetailsModel ad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ad.timeAgo,
                style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ad.statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(ad.title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            ad.priceFormatted,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid(PublicAdDetailsModel ad) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _specCard('النوع', ad.type, Icons.build_outlined),
          _specCard('الحالة', ad.condition, Icons.check_circle_outline),
          _specCard('الضمان', ad.warranty, Icons.verified_outlined),
          _specCard(
            'الموديل',
            ad.vehicleModelLine.isNotEmpty ? ad.vehicleModelLine : '—',
            Icons.directions_car_outlined,
          ),
        ],
      ),
    );
  }

  Widget _specCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.inputBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Icon(icon, size: 20, color: AppColors.primaryColor),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(PublicAdDetailsModel ad) {
    const maxLines = 4;
    final long = ad.description.length > 120;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التفاصيل', style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          Text(
            ad.description,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            maxLines: _descriptionExpanded ? null : maxLines,
            overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          if (long)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => setState(
                  () => _descriptionExpanded = !_descriptionExpanded,
                ),
                child: Text(
                  _descriptionExpanded ? 'اقرأ أقل' : 'اقرأ المزيد',
                  style: AppTextStyles.link,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(PublicAdDetailsModel ad) {
    final loc = ad.location.trim();
    if (loc.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الموقع', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.inputBorderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection(PublicAdDetailsModel ad) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات البائع', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          InkWell(
            onTap: _sellerProfileTapEnabled(ad)
                ? () {
                    final vid = ad.sellerVendorRecordId;
                    if (vid != null && vid > 0) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.vendorProfile,
                        arguments: {
                          'vendorId': vid.toString(),
                          'vendorName': ad.sellerName,
                          'vendorProfileByUserId': false,
                        },
                      );
                    } else if (ad.sellerId != null &&
                        ad.sellerId!.trim().isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.vendorProfile,
                        arguments: {
                          'vendorId': ad.sellerId,
                          'vendorName': ad.sellerName,
                          'vendorProfileByUserId': true,
                        },
                      );
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.inputBorderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chevron_left,
                    color: context.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ad.sellerName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ad.sellerIsVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primaryColor,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        RatingStars(
                          rating: ad.sellerRating,
                          size: 16,
                          reviewCount: ad.sellerReviewCount,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'عرض البروفايل',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: context.surfaceBg,
                        child: ClipOval(
                          child: ad.sellerAvatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: ad.sellerAvatarUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Icon(
                                    Icons.store,
                                    color: context.textHint,
                                    size: 32,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.store,
                                    color: context.textHint,
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  Icons.store,
                                  color: context.textHint,
                                  size: 32,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: OnlineIndicator(
                          isOnline: ad.sellerIsOnline,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.inputBorderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تسوق بأمان',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'قابل البائع في مكان عام، افحص السلعة جيداً قبل الشراء، ولا تحول أي أموال مسبقاً.',
                        style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarAdsSection(PublicAdDetailsModel ad) {
    if (ad.similarAds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعلانات مشابهة', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ad.similarAds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = ad.similarAds[index];
                return _SimilarAdCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PublicAdDetailsModel ad) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launchPhone(ad.sellerPhone),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text('اتصال'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textPrimary,
                  side: BorderSide(color: context.inputBorderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(ad),
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('دردشة الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String? phone) async {
    final uri = phone != null && phone.isNotEmpty
        ? Uri.parse('tel:$phone')
        : Uri.parse('tel:+201000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openChat(PublicAdDetailsModel ad) async {
    final adId = int.tryParse(ad.id);
    if (adId == null || adId <= 0) {
      if (mounted) CustomToast.showError(context, 'تعذّر تحديد الإعلان');
      return;
    }
    final sellerUserId = int.tryParse(ad.sellerId ?? '');
    final currentUserId = int.tryParse(StorageService.getUserId() ?? '');
    if (sellerUserId != null &&
        currentUserId != null &&
        sellerUserId == currentUserId) {
      if (mounted) {
        CustomToast.showError(context, 'لا يمكنك بدء محادثة على إعلانك الخاص');
      }
      return;
    }
    try {
      final repo = ChatRepository();
      int? chatId = await repo.startChatForAd(adId);
      if (chatId == null) {
        if (sellerUserId != null && sellerUserId > 0) {
          chatId = await repo.openChatWithAdSeller(
            sellerUserId: sellerUserId,
            sellerVendorRecordId: ad.sellerVendorRecordId,
          );
        }
      }
      // Fallback for APIs that create/reuse chat but don't return id reliably.
      chatId ??= await repo.findChatIdForAd(adId);
      if (!mounted) return;
      if (chatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId.toString(),
            'chatName': ad.sellerName,
            'vendorName': ad.sellerName,
            'peerPhone': ad.sellerPhone,
            'peerAvatarUrl': ad.sellerAvatarUrl,
            'peerVendorId': ad.sellerVendorRecordId,
          },
        );
      } else {
        CustomToast.showError(
          context,
          'لا يمكن بدء المحادثة مع صاحب هذا الإعلان. جرّب الاتصال أو أعد المحاولة لاحقاً.',
        );
      }
    } catch (e) {
      final repo = ChatRepository();
      int? fallbackChatId;
      // If start endpoint fails, continue with user-based fallback.
      if (sellerUserId != null && sellerUserId > 0) {
        fallbackChatId = await repo.openChatWithAdSeller(
          sellerUserId: sellerUserId,
          sellerVendorRecordId: ad.sellerVendorRecordId,
        );
      }
      fallbackChatId ??= await repo.findChatIdForAd(adId);
      if (!mounted) return;
      if (fallbackChatId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': fallbackChatId.toString(),
            'chatName': ad.sellerName,
            'vendorName': ad.sellerName,
            'peerPhone': ad.sellerPhone,
            'peerAvatarUrl': ad.sellerAvatarUrl,
            'peerVendorId': ad.sellerVendorRecordId,
          },
        );
        return;
      }
      if (mounted) {
        CustomToast.showError(
          context,
          'تعذّر فتح المحادثة. ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }
}

class _SimilarAdCard extends StatelessWidget {
  final SimilarAdItem item;

  const _SimilarAdCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.adDetails,
            arguments: {'adId': item.id},
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.inputBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, __, ___) => _placeholder(ctx),
                        )
                      : _placeholder(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.priceFormatted,
                      style: AppTextStyles.caption.copyWith(
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
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.surfaceBg,
      child: Icon(
        Icons.directions_car_outlined,
        size: 36,
        color: context.textHint,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen image viewer
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullScreenImageViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageCtrl;
  late final List<TransformationController> _zoomCtrl;
  late int _current;

  void _onMatrixChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _zoomCtrl = List<TransformationController>.generate(widget.urls.length, (
      _,
    ) {
      final c = TransformationController();
      c.addListener(_onMatrixChanged);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _zoomCtrl) {
      c.removeListener(_onMatrixChanged);
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  /// When scale ≈ 1, horizontal drags go to [PageView]. When zoomed in/out, pan the image.
  bool _allowPan(int index) {
    final s = _zoomCtrl[index].value.getMaxScaleOnAxis();
    return (s - 1.0).abs() > 0.012;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'ملء الشاشة',
            icon: const Icon(Icons.fit_screen),
            onPressed: () {
              _zoomCtrl[_current].value = Matrix4.identity();
              setState(() {});
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                transformationController: _zoomCtrl[index],
                minScale: 0.2,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                clipBehavior: Clip.none,
                panEnabled: _allowPan(index),
                scaleEnabled: true,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: WatermarkedNetworkImage(
                    imageUrl: widget.urls[index],
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    watermarkWidthFactor: 0.45,
                    placeholder: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
