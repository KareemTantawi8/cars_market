import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../data/models/public_ad_details_model.dart';

/// Public Ad Details Screen
class AdDetailsScreen extends StatefulWidget {
  final String? adId;
  final PublicAdDetailsModel? ad;

  const AdDetailsScreen({
    super.key,
    this.adId,
    this.ad,
  });

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  bool _descriptionExpanded = false;

  PublicAdDetailsModel get _ad {
    return widget.ad ?? _defaultAd;
  }

  static PublicAdDetailsModel get _defaultAd {
    return PublicAdDetailsModel(
      id: '1',
      title: 'كاوتش ميشلان ١٧ بوصة جديد',
      priceFormatted: '٤٥٠٠ ج.م',
      location: 'القاهرة، مدينة نصر',
      timeAgo: 'منذ ٣ ساعات',
      statusLabel: 'جديد',
      imageUrls: [],
      type: 'قطع غيار',
      condition: 'جديد تماماً',
      warranty: 'متاح',
      size: '١٧ بوصة',
      description:
          'طقم كاوتش ميشلان ١٧ بوصة جديد بالكامل لم يستخدم نهائياً. صناعة فرنسية اصلية، تاريخ انتاج ٢٠٢٣. مناسب لجميع السيارات السيدان الحديثة. البيع لعدم الحاجة، السعر نهائي غير قابل للنقاش. المعاينة متاحة في مدينة نصر الحي السابع يومياً من الساعة ٥ مساءً.',
      sellerName: 'أحمد محمد',
      sellerRating: 4.5,
      sellerReviewCount: 26,
      sellerIsOnline: true,
      similarAds: const [
        SimilarAdItem(
          id: 's1',
          title: 'بطارية نسر جافة',
          priceFormatted: '٨٢٠٠ ج.م',
        ),
        SimilarAdItem(
          id: 's2',
          title: 'جنوط سبور ١٩',
          priceFormatted: '٨٣٠٠ ج.م',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSection(),
                  _buildInfoCard(),
                  _buildSpecGrid(),
                  _buildDetailsSection(),
                  _buildLocationSection(),
                  _buildSellerSection(),
                  _buildSimilarAdsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Public Ad Details',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      titleSpacing: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.code, color: AppColors.textSecondary, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final images = _ad.imageUrls.isEmpty ? [null] : _ad.imageUrls;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _imagePageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemBuilder: (context, index) {
                  final url = images[index];
                  return Container(
                    color: AppColors.cardColor,
                    child: url != null
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  _overlayIcon(Icons.favorite_border, () {}),
                  const SizedBox(width: 8),
                  _overlayIcon(Icons.share_outlined, () {}),
                ],
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
                  style: AppTextStyles.captionSmall.copyWith(color: Colors.white),
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

  Widget _imagePlaceholder() {
    return Center(
      child: Icon(
        Icons.directions_car_outlined,
        size: 80,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _ad.timeAgo,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _ad.statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _ad.title,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _ad.priceFormatted,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _ad.location,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid() {
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
          _specCard('النوع', _ad.type, Icons.build_outlined),
          _specCard('الحالة', _ad.condition, Icons.check_circle_outline),
          _specCard('الضمان', _ad.warranty, Icons.verified_outlined),
          _specCard('المقاس', _ad.size, Icons.straighten_outlined),
        ],
      ),
    );
  }

  Widget _specCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
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
                  color: AppColors.textSecondary,
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

  Widget _buildDetailsSection() {
    const maxLines = 4;
    final long = _ad.description.length > 120;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التفاصيل',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 10),
          Text(
            _ad.description,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            maxLines: _descriptionExpanded ? null : maxLines,
            overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          if (long)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
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

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموقع',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              color: AppColors.cardColor,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                  ),
                  Center(
                    child: Material(
                      color: AppColors.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'عرض على الخريطة',
                                style: AppTextStyles.buttonSmall.copyWith(
                                  color: Colors.white,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات البائع',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ad.sellerName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingStars(
                        rating: _ad.sellerRating,
                        size: 16,
                        reviewCount: _ad.sellerReviewCount,
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceColor,
                      backgroundImage: _ad.sellerAvatarUrl != null
                          ? NetworkImage(_ad.sellerAvatarUrl!)
                          : null,
                      child: _ad.sellerAvatarUrl == null
                          ? Icon(Icons.person, color: AppColors.textHint, size: 32)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: OnlineIndicator(
                        isOnline: _ad.sellerIsOnline,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primaryColor, size: 24),
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

  Widget _buildSimilarAdsSection() {
    if (_ad.similarAds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعلانات مشابهة',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ad.similarAds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _ad.similarAds[index];
                return _SimilarAdCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
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
                onPressed: () => _launchPhone(_ad.sellerPhone),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text('اتصال'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.inputBorder),
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
                onPressed: () => _openChat(),
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

  void _openChat() {
    Navigator.pushNamed(
      context,
      AppRoutes.chatRoom,
      arguments: {
        'chatId': _ad.sellerId ?? _ad.id,
        'chatName': _ad.sellerName,
        'vendorName': _ad.sellerName,
      },
    );
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
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
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

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceColor,
      child: Icon(
        Icons.directions_car_outlined,
        size: 36,
        color: AppColors.textHint,
      ),
    );
  }
}
