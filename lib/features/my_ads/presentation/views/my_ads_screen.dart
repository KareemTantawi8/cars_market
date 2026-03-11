import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/my_ads_cubit.dart';

/// Filter chip type for My Ads list
enum MyAdsFilter {
  all,
  active,      // approved
  underReview, // pending
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAdsCubit>().loadMyAds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdModel> _filterList(List<AdModel> ads) {
    switch (_selectedFilter) {
      case MyAdsFilter.all:
        return ads;
      case MyAdsFilter.active:
        return ads.where((a) => a.statusNormalized == 'approved').toList();
      case MyAdsFilter.underReview:
        return ads.where((a) => a.statusNormalized == 'pending').toList();
    }
  }

  int _countByStatus(List<AdModel> ads, String normalizedStatus) {
    return ads.where((a) => a.statusNormalized == normalizedStatus).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createAd),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة إعلان',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: BlocConsumer<MyAdsCubit, MyAdsState>(
                listener: (context, state) {
                  if (state is MyAdsError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MyAdsLoading || state is MyAdsInitial) {
                    return const Center(child: LoadingIndicator());
                  }
                  if (state is MyAdsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.read<MyAdsCubit>().loadMyAds(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is MyAdsLoaded) {
                    final filtered = _filterList(state.ads);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedFilter == MyAdsFilter.all ? 'لا توجد إعلانات' : 'لا توجد إعلانات في هذا التصنيف',
                          style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MyAdCard(ad: filtered[index]),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: context.textPrimary, size: 26),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              Positioned(
                right: 10,
                top: 10,
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
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'إعلاناتي',
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة بيع وشراء قطع غيار السيارات',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Material(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.filter_list, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.search, color: context.textSecondary, size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.input.copyWith(color: context.textPrimary),
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'ابحث في إعلاناتك...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

  Widget _buildFilterChips() {
    return BlocBuilder<MyAdsCubit, MyAdsState>(
      buildWhen: (a, b) => a is MyAdsLoaded && b is MyAdsLoaded,
      builder: (context, state) {
        final ads = state is MyAdsLoaded ? state.ads : <AdModel>[];
        final totalCount = ads.length;
        final activeCount = _countByStatus(ads, 'approved');
        final underReviewCount = _countByStatus(ads, 'pending');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _FilterChip(
                  label: 'الكل ($totalCount)',
                  isSelected: _selectedFilter == MyAdsFilter.all,
                  onTap: () => setState(() => _selectedFilter = MyAdsFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterChip(
                  label: 'نشط ($activeCount)',
                  isSelected: _selectedFilter == MyAdsFilter.active,
                  onTap: () => setState(() => _selectedFilter = MyAdsFilter.active),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterChip(
                  label: 'قيد المراجعة ($underReviewCount)',
                  isSelected: _selectedFilter == MyAdsFilter.underReview,
                  onTap: () => setState(() => _selectedFilter = MyAdsFilter.underReview),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryColor : context.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : context.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyAdCard extends StatelessWidget {
  final AdModel ad;

  const _MyAdCard({required this.ad});

  String? get _imageUrl {
    final path = ad.firstImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  /// Optional: show "مميز" when API supports is_featured. Placeholder for now.
  bool get _isFeatured => false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.adDetails,
          arguments: {'adId': ad.id},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image on the right in RTL (first in Row)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(context),
                              errorWidget: (_, __, ___) => _placeholder(context),
                            )
                          : _placeholder(context),
                    ),
                  ),
                  if (_isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.ratingStar,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'مميز',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(Icons.more_vert, color: context.textSecondary, size: 22),
                            onPressed: () => _showAdMenu(context),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                      Text(
                        ad.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.priceFormatted,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            ad.viewsFormatted,
                            style: AppTextStyles.caption.copyWith(color: context.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          _StatusChip(status: ad.statusNormalized),
                        ],
                      ),
                    ],
                  ),
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
      child: Icon(Icons.directions_car_outlined, size: 40, color: context.textHint),
    );
  }

  void _showAdMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility, color: context.textPrimary),
              title: const Text('عرض الإعلان'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.adDetails, arguments: {'adId': ad.id});
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: context.textPrimary),
              title: const Text('تعديل'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.editAd,
                  arguments: ad,
                );
                if (context.mounted && result == true) {
                  context.read<MyAdsCubit>().loadMyAds();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('حذف', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<MyAdsCubit>().deleteAd(ad.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الإعلان'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'approved';
    final isUnderReview = status == 'pending';
    final bgColor = isActive
        ? AppColors.success.withOpacity(0.2)
        : isUnderReview
            ? AppColors.warning.withOpacity(0.2)
            : context.textHint.withOpacity(0.2);
    final fgColor = isActive
        ? AppColors.success
        : isUnderReview
            ? AppColors.warning
            : context.textSecondary;
    final label = status == 'approved' ? 'نشط' : status == 'pending' ? 'قيد المراجعة' : 'معلق';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fgColor,
              shape: BoxShape.circle,
            ),
          ),
          if (isUnderReview) ...[const SizedBox(width: 4), Icon(Icons.schedule, size: 12, color: fgColor)],
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
