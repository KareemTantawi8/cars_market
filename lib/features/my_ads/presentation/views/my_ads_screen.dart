import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/my_ad_model.dart';

/// Filter chip type for My Ads list
enum MyAdsFilter {
  all,
  active,
  underReview,
  pending,
}

/// My Ads screen - إعلاناتي (customer's ad management)
class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final _searchController = TextEditingController();
  MyAdsFilter _selectedFilter = MyAdsFilter.all;

  // Mock data matching the design
  static final List<MyAdModel> _allAds = [
    const MyAdModel(
      id: '1',
      title: 'طقم جنوط سبور 17 بوصة بحالة الزيرو',
      priceFormatted: '5,000 ج.م',
      status: MyAdStatus.active,
      viewCount: 120,
      isFeatured: true,
    ),
    const MyAdModel(
      id: '2',
      title: 'محرك تويوتا كامري 2015 كامل',
      priceFormatted: '45,000 ج.م',
      status: MyAdStatus.underReview,
      viewCount: -1,
    ),
    const MyAdModel(
      id: '3',
      title: 'سيارة تويوتا كورولا 2020',
      priceFormatted: '380,000 ج.م',
      status: MyAdStatus.active,
      viewCount: 843,
    ),
    const MyAdModel(
      id: '4',
      title: 'فانوس أمامي أيسر تويوتا',
      priceFormatted: '1,200 ج.م',
      status: MyAdStatus.active,
      viewCount: 45,
    ),
  ];

  List<MyAdModel> get _filteredAds {
    switch (_selectedFilter) {
      case MyAdsFilter.all:
        return _allAds;
      case MyAdsFilter.active:
        return _allAds.where((a) => a.status == MyAdStatus.active).toList();
      case MyAdsFilter.underReview:
        return _allAds.where((a) => a.status == MyAdStatus.underReview).toList();
      case MyAdsFilter.pending:
        return _allAds.where((a) => a.status == MyAdStatus.pending).toList();
    }
  }

  int get _activeCount =>
      _allAds.where((a) => a.status == MyAdStatus.active).length;
  int get _underReviewCount =>
      _allAds.where((a) => a.status == MyAdStatus.underReview).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _filteredAds.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MyAdCard(ad: _filteredAds[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.notificationDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعلاناتي',
                  style: AppTextStyles.headingMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة بيع وشراء قطع غيار السيارات',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.tune,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () {
                // TODO: open filter sheet
              },
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'ابحث في إعلاناتك...',
                  hintStyle: AppTextStyles.inputHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            isSelected: _selectedFilter == MyAdsFilter.all,
            onTap: () => setState(() => _selectedFilter = MyAdsFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'نشط ($_activeCount)',
            isSelected: _selectedFilter == MyAdsFilter.active,
            onTap: () => setState(() => _selectedFilter = MyAdsFilter.active),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'قيد المراجعة ($_underReviewCount)',
            isSelected: _selectedFilter == MyAdsFilter.underReview,
            onTap: () =>
                setState(() => _selectedFilter = MyAdsFilter.underReview),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'معلق',
            isSelected: _selectedFilter == MyAdsFilter.pending,
            onTap: () => setState(() => _selectedFilter = MyAdsFilter.pending),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryColor : AppColors.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyAdCard extends StatelessWidget {
  final MyAdModel ad;

  const _MyAdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (right side in RTL)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                _buildImage(),
                if (ad.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'مميز',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content (left side in RTL)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => _showAdMenu(context),
                      ),
                    ],
                  ),
                  Text(
                    ad.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ad.priceFormatted,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(status: ad.status),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ad.viewsLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
      return Image.network(
        ad.imageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.surfaceColor,
      child: Icon(
        Icons.directions_car_outlined,
        size: 40,
        color: AppColors.textHint,
      ),
    );
  }

  void _showAdMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.textPrimary),
              title: const Text('تعديل'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.textPrimary),
              title: const Text('عرض الإعلان'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin, color: AppColors.textPrimary),
              title: const Text('تمييز'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'حذف',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final MyAdStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == MyAdStatus.active;
    final isUnderReview = status == MyAdStatus.underReview;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success
                : isUnderReview
                    ? AppColors.warning
                    : AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
        if (isUnderReview) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.schedule,
            size: 12,
            color: AppColors.warning,
          ),
        ],
        const SizedBox(width: 4),
        Text(
          _label(status),
          style: AppTextStyles.caption.copyWith(
            color: isActive
                ? AppColors.success
                : isUnderReview
                    ? AppColors.warning
                    : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _label(MyAdStatus s) {
    switch (s) {
      case MyAdStatus.active:
        return 'نشط';
      case MyAdStatus.underReview:
        return 'قيد المراجعة';
      case MyAdStatus.pending:
        return 'معلق';
    }
  }
}
