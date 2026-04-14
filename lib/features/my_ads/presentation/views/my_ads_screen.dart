import 'dart:math' as math;

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

/// My Ads screen - إعلاناتي (customer's own ads only)
class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final _searchController = TextEditingController();
  MyAdsFilter _selectedFilter = MyAdsFilter.all;
  String? _myAdsSearch;

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
    Iterable<AdModel> result = ads;

    // Status filter
    switch (_selectedFilter) {
      case MyAdsFilter.all:
        break;
      case MyAdsFilter.active:
        result = result.where((a) => a.statusNormalized == 'approved');
        break;
      case MyAdsFilter.underReview:
        result = result.where((a) => a.statusNormalized == 'pending');
        break;
    }

    // Local search filter for "My Ads" tab
    final query = _myAdsSearch;
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      result = result.where((a) => a.title.toLowerCase().contains(lower));
    }

    return result.toList();
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
            Expanded(child: _buildMyAdsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAdsList() {
    return BlocConsumer<MyAdsCubit, MyAdsState>(
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
                Text(
                  state.message,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
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
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.inputBorderColor),
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
                onChanged: (text) {
                  setState(() {
                    _myAdsSearch = text.trim().isEmpty ? null : text.trim();
                  });
                },
                onSubmitted: (_) => _onSearchPressed(),
                decoration: InputDecoration(
                  hintText: 'ابحث في إعلاناتك...',
                  hintStyle: AppTextStyles.input.copyWith(
                    color: context.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (_myAdsSearch != null && _myAdsSearch!.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, color: context.textSecondary, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _myAdsSearch = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _onSearchPressed() {
    final text = _searchController.text.trim();
    setState(() {
      _myAdsSearch = text.isEmpty ? null : text;
    });
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'الكل',
              isSelected: _selectedFilter == MyAdsFilter.all,
              onTap: () => setState(() => _selectedFilter = MyAdsFilter.all),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterChip(
              label: 'نشط',
              isSelected: _selectedFilter == MyAdsFilter.active,
              onTap: () => setState(() => _selectedFilter = MyAdsFilter.active),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterChip(
              label: 'قيد المراجعة',
              isSelected: _selectedFilter == MyAdsFilter.underReview,
              onTap: () => setState(() => _selectedFilter = MyAdsFilter.underReview),
            ),
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

class _MyAdCard extends StatefulWidget {
  final AdModel ad;

  const _MyAdCard({required this.ad});

  @override
  State<_MyAdCard> createState() => _MyAdCardState();
}

class _MyAdCardState extends State<_MyAdCard> {
  late final PageController _pageController;
  int _pageIndex = 0;

  AdModel get ad => widget.ad;

  bool get _isFeatured => false;

  Color get _statusColor {
    switch (ad.statusNormalized) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  List<String> get _imageUrls {
    final out = <String>[];
    for (final path in ad.images) {
      if (path.isEmpty) continue;
      if (path.startsWith('http')) {
        out.add(path);
      } else {
        out.add('${AppConstants.storageBaseUrl}/$path');
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openAdDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.adDetails,
      arguments: {'adId': ad.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _imageUrls;
    final pageCount = math.max(1, urls.length);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_statusColor, _statusColor.withOpacity(0.4)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: context.surfaceBg,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pageCount,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (context, index) {
                        final url = urls.isEmpty ? null : urls[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTap: () => _openAdDetails(context),
                          child: url != null
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => _placeholder(context),
                                  errorWidget: (_, __, ___) => _placeholder(context),
                                )
                              : _placeholder(context),
                        );
                      },
                    ),
                  ),
                  if (urls.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(urls.length, (i) {
                          final active = i == _pageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? AppColors.primaryColor : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  if (_isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ratingStar,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: Colors.black87),
                            const SizedBox(width: 2),
                            Text(
                              'مميز',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Material(
              color: context.cardBg,
              child: InkWell(
                onTap: () => _openAdDetails(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: _buildInfoBody(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showAdMenu(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.more_horiz_rounded, color: context.textSecondary, size: 20),
              ),
            ),
            _StatusChip(status: ad.statusNormalized),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ad.title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 16,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ad.priceFormatted,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.remove_red_eye_outlined, size: 14, color: context.textHint),
            const SizedBox(width: 4),
            Text(
              ad.viewsFormatted,
              style: AppTextStyles.caption.copyWith(
                color: context.textHint,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.surfaceBg,
      child: Center(
        child: Icon(Icons.directions_car_outlined, size: 48, color: context.textHint),
      ),
    );
  }

  void _showAdMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ctx.inputBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.visibility_outlined, color: AppColors.primaryColor, size: 20),
                ),
                title: const Text('عرض الإعلان'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.adDetails, arguments: {'adId': ad.id});
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_outlined, color: AppColors.warning, size: 20),
                ),
                title: const Text('تعديل الإعلان'),
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                ),
                title: Text('حذف الإعلان', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
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

    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (isActive) {
      bgColor = AppColors.success.withOpacity(0.15);
      fgColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      label = 'نشط';
    } else if (isUnderReview) {
      bgColor = AppColors.warning.withOpacity(0.15);
      fgColor = AppColors.warning;
      icon = Icons.schedule_rounded;
      label = 'قيد المراجعة';
    } else {
      bgColor = context.textHint.withOpacity(0.15);
      fgColor = context.textSecondary;
      icon = Icons.pause_circle_outline_rounded;
      label = 'معلق';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
