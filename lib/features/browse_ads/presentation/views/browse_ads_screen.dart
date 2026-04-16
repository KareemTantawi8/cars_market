import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/ads_list_cubit.dart';
import '../../../home/data/models/category_models.dart';
import '../../../home/presentation/cubit/category_cubit.dart';

/// Browse Ads — single-screen with inline filter chips
class BrowseAdsScreen extends StatefulWidget {
  const BrowseAdsScreen({super.key});

  @override
  State<BrowseAdsScreen> createState() => _BrowseAdsScreenState();
}

class _BrowseAdsScreenState extends State<BrowseAdsScreen> {
  BrandModel? _brand;
  CarModelModel? _model;
  YearModel? _year;
  String? _condition; // 'new' | 'used' | null

  bool get _hasFilter =>
      _brand != null || _model != null || _year != null || _condition != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cat = context.read<CategoryCubit>().state;
      if (cat is CategoryInitial || (cat is CategoryLoaded && cat.brands.isEmpty)) {
        context.read<CategoryCubit>().loadBrands();
      }
      context.read<AdsListCubit>().loadAds();
    });
  }

  // ── filter application ────────────────────────────────────────────────────

  void _applyFilters() {
    context.read<AdsListCubit>().loadAds(
      brandId: _brand?.id,
      modelId: _model?.id,
      yearId: _year?.id,
      condition: _condition,
    );
  }

  void _clearFilters() {
    setState(() {
      _brand = null;
      _model = null;
      _year = null;
      _condition = null;
    });
    context.read<CategoryCubit>().clearSelections();
    context.read<AdsListCubit>().loadAds();
  }

  // ── bottom sheet helpers ──────────────────────────────────────────────────

  Future<void> _showBrandPicker() async {
    final catState = context.read<CategoryCubit>().state;
    List<BrandModel> brands = catState is CategoryLoaded ? catState.brands : [];

    final picked = await _showPickerSheet<BrandModel>(
      title: 'اختر الماركة',
      items: brands,
      selected: _brand,
      labelOf: (b) => b.displayName,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _brand = picked;
      _model = null;
      _year = null;
    });
    context.read<CategoryCubit>().selectBrand(picked);
    _applyFilters();
  }

  Future<void> _showModelPicker() async {
    if (_brand == null) return;
    final catState = context.read<CategoryCubit>().state;
    List<CarModelModel> models =
        catState is CategoryLoaded ? catState.models : [];

    if (models.isEmpty) {
      // Load on-demand if not yet loaded
      await context.read<CategoryCubit>().loadModels(_brand!.id);
      if (!mounted) return;
      final updated = context.read<CategoryCubit>().state;
      models = updated is CategoryLoaded ? updated.models : [];
    }

    final picked = await _showPickerSheet<CarModelModel>(
      title: 'اختر الموديل',
      items: models,
      selected: _model,
      labelOf: (m) => m.displayName,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _model = picked;
      _year = null;
    });
    context.read<CategoryCubit>().selectModel(picked);
    _applyFilters();
  }

  Future<void> _showYearPicker() async {
    if (_model == null) return;
    final catState = context.read<CategoryCubit>().state;
    List<YearModel> years = catState is CategoryLoaded ? catState.years : [];

    if (years.isEmpty) {
      await context.read<CategoryCubit>().loadYears(_model!.id);
      if (!mounted) return;
      final updated = context.read<CategoryCubit>().state;
      years = updated is CategoryLoaded ? updated.years : [];
    }

    final picked = await _showPickerSheet<YearModel>(
      title: 'اختر السنة',
      items: years,
      selected: _year,
      labelOf: (y) => y.displayName,
    );
    if (picked == null || !mounted) return;
    setState(() => _year = picked);
    _applyFilters();
  }

  Future<void> _showConditionPicker() async {
    const options = [
      ('new', 'جديد'),
      ('used', 'مستعمل'),
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PickerSheet<String>(
          title: 'حالة السيارة',
          items: options.map((e) => e.$1).toList(),
          selected: _condition,
          labelOf: (v) => options.firstWhere((e) => e.$1 == v).$2,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // Toggle: tap selected condition again to deselect
    setState(() => _condition = picked == _condition ? null : picked);
    _applyFilters();
  }

  Future<T?> _showPickerSheet<T>({
    required String title,
    required List<T> items,
    required T? selected,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, sc) => _PickerSheet<T>(
            title: title,
            items: items,
            selected: selected,
            labelOf: labelOf,
            scrollController: sc,
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'تصفح الإعلانات',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_hasFilter)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'مسح',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterRow(
            brand: _brand,
            model: _model,
            year: _year,
            condition: _condition,
            onBrandTap: _showBrandPicker,
            onModelTap: _brand != null ? _showModelPicker : null,
            onYearTap: _model != null ? _showYearPicker : null,
            onConditionTap: _showConditionPicker,
          ),
          const Divider(height: 1),
          Expanded(child: _AdsList()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final BrandModel? brand;
  final CarModelModel? model;
  final YearModel? year;
  final String? condition;
  final VoidCallback onBrandTap;
  final VoidCallback? onModelTap;
  final VoidCallback? onYearTap;
  final VoidCallback onConditionTap;

  const _FilterRow({
    required this.brand,
    required this.model,
    required this.year,
    required this.condition,
    required this.onBrandTap,
    required this.onModelTap,
    required this.onYearTap,
    required this.onConditionTap,
  });

  @override
  Widget build(BuildContext context) {
    const conditionLabels = {'new': 'جديد', 'used': 'مستعمل'};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _Chip(
            label: brand?.displayName ?? 'الماركة',
            active: brand != null,
            onTap: onBrandTap,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: model?.displayName ?? 'الموديل',
            active: model != null,
            enabled: onModelTap != null,
            onTap: onModelTap ?? () {},
          ),
          const SizedBox(width: 8),
          _Chip(
            label: year?.displayName ?? 'السنة',
            active: year != null,
            enabled: onYearTap != null,
            onTap: onYearTap ?? () {},
          ),
          const SizedBox(width: 8),
          _Chip(
            label: condition != null
                ? conditionLabels[condition] ?? condition!
                : 'الحالة',
            active: condition != null,
            onTap: onConditionTap,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.primaryColor
        : enabled
            ? context.cardBg
            : context.inputBg;
    final fg = active
        ? Colors.white
        : enabled
            ? context.textPrimary
            : context.textHint;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryColor : context.inputBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: fg,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: fg,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T) labelOf;
  final ScrollController? scrollController;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.labelOf,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.inputBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'لا توجد خيارات',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selected;
                return ListTile(
                  title: Text(
                    labelOf(item),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.primaryColor : context.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primaryColor, size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ads List
// ─────────────────────────────────────────────────────────────────────────────

class _AdsList extends StatelessWidget {
  const _AdsList();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdsListCubit, AdsListState>(
      listener: (context, state) {
        if (state is AdsListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is AdsListInitial || state is AdsListLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (state is AdsListError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      context.read<AdsListCubit>().loadAds(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        if (state is AdsListLoaded) {
          final ads = state.ads;
          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 56, color: context.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد إعلانات',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: context.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: ads.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AdCard(ad: ads[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ad Card
// ─────────────────────────────────────────────────────────────────────────────

class _AdCard extends StatefulWidget {
  final AdModel ad;

  const _AdCard({required this.ad});

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  late final PageController _pageController;
  int _pageIndex = 0;

  AdModel get ad => widget.ad;

  List<String> get _imageUrls {
    final out = <String>[];
    for (final path in ad.images) {
      if (path.isEmpty) continue;
      out.add(path.startsWith('http')
          ? path
          : '${AppConstants.storageBaseUrl}/$path');
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

  void _openDetails(BuildContext context) {
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image carousel ────────────────────────────────────────────
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: context.surfaceBg,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pageCount,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (i) =>
                          setState(() => _pageIndex = i),
                      itemBuilder: (context, index) {
                        final url =
                            urls.isEmpty ? null : urls[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTap: () => _openDetails(context),
                          child: url != null
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) =>
                                      _placeholder(context),
                                  errorWidget: (_, __, ___) =>
                                      _placeholder(context),
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
                              color: active
                                  ? AppColors.primaryColor
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info ──────────────────────────────────────────────────────
            Material(
              color: context.cardBg,
              child: InkWell(
                onTap: () => _openDetails(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ad.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Condition badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ad.condition == 'new'
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : AppColors.primaryColor
                                      .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ad.conditionLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: ad.condition == 'new'
                                    ? Colors.green.shade700
                                    : AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ad.priceFormatted,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ad.locationLabel != null &&
                          ad.locationLabel!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ad.locationLabel!.trim(),
                                style: AppTextStyles.caption.copyWith(
                                  color: context.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.surfaceBg,
      child: Center(
        child: Icon(Icons.directions_car_outlined,
            size: 40, color: context.textHint),
      ),
    );
  }
}
