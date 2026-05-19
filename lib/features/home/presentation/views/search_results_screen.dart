import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/auth/auth_guard.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../data/models/search_request_model.dart';
import '../../data/models/search_response_model.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/search_cubit.dart';

/// Search Results Screen
class SearchResultsScreen extends StatefulWidget {
  final SearchRequestModel? searchRequest;
  final SearchResponseModel? searchResponse;

  const SearchResultsScreen({
    super.key,
    this.searchRequest,
    this.searchResponse,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  int _currentNavIndex = 1; // Search is at index 1

  List<String> get _activeFilters {
    final request = widget.searchRequest;
    if (request == null) return [];
    
    final filters = <String>[];
    if (request.partName != null && request.partName!.isNotEmpty) {
      filters.add(request.partName!);
    }
    if (request.brandName != null && request.brandName!.isNotEmpty) {
      filters.add(request.brandName!);
    }
    if (request.modelName != null && request.modelName!.isNotEmpty) {
      filters.add(request.modelName!);
    }
    if (request.yearName != null && request.yearName!.isNotEmpty) {
      filters.add(request.yearName!);
    }
    if (request.governorateName != null && request.governorateName!.isNotEmpty) {
      filters.add(request.governorateName!);
    }
    return filters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // TODO: Open filter dialog
          },
        ),
        title: Text('نتائج البحث', style: AppTextStyles.headingMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          if (_activeFilters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: context.surfaceBg,
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
                              backgroundColor: context.cardBg,
                              labelStyle: AppTextStyles.bodySmall,
                              deleteIcon: Icon(
                                Icons.close,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              onDeleted: () {
                                setState(() {
                                  // Note: This won't actually remove from search, just UI
                                  // In a real app, you'd trigger a new search
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
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                // Use widget data if available, otherwise use state
                final suppliers = widget.searchResponse?.suppliers ?? 
                    (state is SearchSuccess ? state.response.suppliers : <SupplierModel>[]);

                if (state is SearchLoading && suppliers.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is SearchError && suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.message,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'إعادة المحاولة',
                          onPressed: () {
                            // Retry search if we have the request
                            if (widget.searchRequest != null) {
                              context.read<SearchCubit>().searchSuppliers(
                                    partName: widget.searchRequest!.partName,
                                    brandId: widget.searchRequest!.brandId,
                                    modelId: widget.searchRequest!.modelId,
                                    yearId: widget.searchRequest!.yearId,
                                    governorateId: widget.searchRequest!.governorateId,
                                    brandName: widget.searchRequest!.brandName,
                                    modelName: widget.searchRequest!.modelName,
                                    yearName: widget.searchRequest!.yearName,
                                    governorateName: widget.searchRequest!.governorateName,
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }

                // Display results
                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: context.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'لم نجد موردين يطابقون معايير البحث',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...suppliers.map((supplier) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSearchResultCard(
                            imageUrl: supplier.imageUrl,
                            name: supplier.name,
                            isOnline: supplier.isOnline,
                            isVerified: supplier.isVerified,
                            rating: supplier.rating,
                            reviewCount: supplier.reviewCount,
                            location: supplier.location,
                            supportedBrands: supplier.supportedBrands,
                            distance: supplier.distance,
                            supplierId: supplier.id.toString(),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      // Customer Reviews Section
                      _buildCustomerReviewsSection(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchResultCard({
    required String? imageUrl,
    required String name,
    required bool isOnline,
    bool isVerified = false,
    required double rating,
    required int reviewCount,
    required String location,
    required List<String> supportedBrands,
    String? distance,
    String? supplierId,
  }) {
    return Card(
      color: context.cardBg,
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
                // Name + verified
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTextStyles.headingSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ],
                  ],
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
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distance != null ? '$location ($distance)' : location,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                if (supportedBrands.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Brands
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: context.textSecondary,
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
                        'vendorId': supplierId ?? 'vendor_search_1',
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
      color: context.surfaceBg,
      child: Icon(
        Icons.store,
        size: 64,
        color: context.textSecondary,
      ),
    );
  }

  Widget _buildCustomerReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
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
                      color: context.textSecondary,
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
              backgroundColor: context.surfaceBg,
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
      decoration: BoxDecoration(
        color: context.surfaceBg,
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
                AuthGuard.pushProtected(context, AppRoutes.orders);
              }),
              _buildNavItem(Icons.chat_bubble, 'المحادثات', 2, () {
                AuthGuard.pushProtected(context, AppRoutes.chatList);
              }),
              _buildNavItem(Icons.person, 'حسابي', 3, () {
                AuthGuard.pushProtected(context, AppRoutes.profile);
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
                  : context.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primaryColor
                    : context.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

