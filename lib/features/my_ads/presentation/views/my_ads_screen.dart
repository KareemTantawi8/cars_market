import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
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
        return ads.where((a) => a.status == 'approved').toList();
      case MyAdsFilter.underReview:
        return ads.where((a) => a.status == 'pending').toList();
    }
  }

  int _countByStatus(List<AdModel> ads, String status) {
    return ads.where((a) => a.status == status).length;
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
                    return const Center(child: CircularProgressIndicator());
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
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.notificationDot, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إعلاناتي', style: AppTextStyles.headingMedium),
                const SizedBox(height: 4),
                Text(
                  'إدارة بيع وشراء قطع غيار السيارات',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createAd),
            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primaryColor),
            label: Text('إضافة إعلان', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
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
            IconButton(icon: const Icon(Icons.tune, color: AppColors.textSecondary, size: 22), onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.input,
                decoration: const InputDecoration(
                  hintText: 'ابحث في إعلاناتك...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.search, color: AppColors.textSecondary, size: 22)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<MyAdsCubit, MyAdsState>(
      buildWhen: (a, b) => a is MyAdsLoaded && b is MyAdsLoaded,
      builder: (context, state) {
        final ads = state is MyAdsLoaded ? state.ads : <AdModel>[];
        final activeCount = _countByStatus(ads, 'approved');
        final underReviewCount = _countByStatus(ads, 'pending');
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(label: 'الكل', isSelected: _selectedFilter == MyAdsFilter.all, onTap: () => setState(() => _selectedFilter = MyAdsFilter.all)),
              const SizedBox(width: 8),
              _FilterChip(label: 'نشط ($activeCount)', isSelected: _selectedFilter == MyAdsFilter.active, onTap: () => setState(() => _selectedFilter = MyAdsFilter.active)),
              const SizedBox(width: 8),
              _FilterChip(label: 'قيد المراجعة ($underReviewCount)', isSelected: _selectedFilter == MyAdsFilter.underReview, onTap: () => setState(() => _selectedFilter = MyAdsFilter.underReview)),
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
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
              child: SizedBox(
                width: 120,
                height: 120,
                child: _imageUrl != null
                    ? Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
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
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _showAdMenu(context),
                        ),
                      ],
                    ),
                    Text(
                      ad.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.priceFormatted,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(status: ad.status),
                        const SizedBox(width: 12),
                        Icon(Icons.visibility_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('-- مشاهدة', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceColor,
      child: Icon(Icons.directions_car_outlined, size: 40, color: AppColors.textHint),
    );
  }

  void _showAdMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.textPrimary),
              title: const Text('عرض الإعلان'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.adDetails, arguments: {'adId': ad.id});
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : isUnderReview ? AppColors.warning : AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
        if (isUnderReview) const SizedBox(width: 4),
        if (isUnderReview) Icon(Icons.schedule, size: 12, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          status == 'approved' ? 'نشط' : status == 'pending' ? 'قيد المراجعة' : 'معلق',
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.success : isUnderReview ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
