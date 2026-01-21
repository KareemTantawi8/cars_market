import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';

/// Search Results Screen
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final List<String> _activeFilters = ['2022', 'مساعدين', 'تويوتا كورولا'];
  int _currentNavIndex = 1; // Search is at index 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Open filter dialog
          },
        ),
        title: Text(
          'نتائج البحث',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Chips
            if (_activeFilters.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceColor,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _activeFilters.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(filter),
                                backgroundColor: AppColors.cardColor,
                                labelStyle: AppTextStyles.bodySmall,
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _activeFilters.remove(filter);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Search Results
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchResultCard(
                    imageUrl:
                        'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
                    name: 'الشركة الهندسية لقطع الغيار',
                    isOnline: true,
                    rating: 4.5,
                    reviewCount: 120,
                    location: 'القاهرة - ش دمشق',
                    supportedBrands: ['تويوتا', 'نيسان', 'ميتسوبيشي'],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchResultCard(
                    imageUrl:
                        'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=800',
                    name: 'مركز الفرسان لقطع الغيار',
                    isOnline: true,
                    rating: 4.5,
                    reviewCount: 85,
                    location: 'القاهرة',
                    supportedBrands: [],
                  ),
                  const SizedBox(height: 24),
                  // Customer Reviews Section
                  _buildCustomerReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchResultCard({
    required String? imageUrl,
    required String name,
    required bool isOnline,
    required double rating,
    required int reviewCount,
    required String location,
    required List<String> supportedBrands,
  }) {
    return Card(
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              // Online Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.offline,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'أونلاين',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                // Rating
                Row(
                  children: [
                    RatingStars(rating: rating, size: 16, reviewCount: reviewCount),
                  ],
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
                if (supportedBrands.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Brands
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الماركات: ${supportedBrands.join('، ')}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Contact Button
                PrimaryButton(
                  text: 'تواصل مع التاجر',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.vendorProfile,
                      arguments: {
                        'vendorId': 'vendor_search_1',
                        'vendorName': name,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppColors.surfaceColor,
      child: const Icon(
        Icons.store,
        size: 64,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCustomerReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آراء العملاء عن التجار',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '4.8',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: 4.8, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'reviews 205',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Rating Breakdown
          _buildRatingBreakdown(5, 80),
          const SizedBox(height: 12),
          _buildRatingBreakdown(4, 15),
          const SizedBox(height: 12),
          _buildRatingBreakdown(3, 3),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown(int stars, int percentage) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$stars',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.surfaceColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.search, 'البحث', 0, () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              }),
              _buildNavItem(Icons.shopping_cart, 'طلباتي', 1, () {
                // TODO: Navigate to orders
              }),
              _buildNavItem(Icons.chat_bubble, 'المحادثات', 2, () {
                Navigator.pushNamed(context, AppRoutes.chatList);
              }),
              _buildNavItem(Icons.person, 'حسابي', 3, () {
                Navigator.pushNamed(context, AppRoutes.profile);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = index == _currentNavIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentNavIndex = index);
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

