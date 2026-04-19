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
      await context.read<CategoryCubit>().loadModels(_brand!.id);
      if (!mounted) return;
      final updated = context.read<CategoryCubit>().state;
      models = updated is CategoryLoaded ? updated.models : [];
    }

    // Track whether "عرض الكل" was tapped
    bool viewAllSelected = false;

    final picked = await _showPickerSheet<CarModelModel>(
      title: 'اختر الموديل',
      items: models,
      selected: _model,
      labelOf: (m) => m.displayName,
      onViewAll: () => viewAllSelected = true,
      viewAllSubtitle: 'جميع إعلانات هذه الماركة',
    );
    if (!mounted) return;

    if (viewAllSelected) {
      // Show all ads for this brand — no model filter
      setState(() {
        _model = null;
        _year = null;
      });
      context.read<CategoryCubit>().clearModelAndYearKeepingBrand();
      _applyFilters();
    } else if (picked != null) {
      setState(() {
        _model = picked;
        _year = null;
      });
      context.read<CategoryCubit>().selectModel(picked);
      _applyFilters();
    }
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

    // Track whether "عرض الكل" was tapped
    bool viewAllSelected = false;

    final picked = await _showPickerSheet<YearModel>(
      title: 'اختر السنة',
      items: years,
      selected: _year,
      labelOf: (y) => y.displayName,
      onViewAll: () => viewAllSelected = true,
      viewAllSubtitle: 'جميع إعلانات هذا الموديل بكل السنوات',
    );
    if (!mounted) return;

    if (viewAllSelected) {
      // Show all ads for this model — no year filter
      setState(() => _year = null);
      context.read<CategoryCubit>().clearYearKeepingBrandAndModel();
      _applyFilters();
    } else if (picked != null) {
      setState(() => _year = picked);
      _applyFilters();
    }
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
    VoidCallback? onViewAll,
    String? viewAllSubtitle,
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
            onViewAll: onViewAll,
            viewAllSubtitle: viewAllSubtitle,
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
            brandSelectedNoModel: _brand != null && _model == null,
            modelSelectedNoYear: _model != null && _year == null,
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
  /// True when a brand is chosen but no specific model (all models for brand).
  final bool brandSelectedNoModel;
  /// True when a model is chosen but no year (all years for model).
  final bool modelSelectedNoYear;
  final VoidCallback onBrandTap;
  final VoidCallback? onModelTap;
  final VoidCallback? onYearTap;
  final VoidCallback onConditionTap;

  const _FilterRow({
    required this.brand,
    required this.model,
    required this.year,
    required this.condition,
    this.brandSelectedNoModel = false,
    this.modelSelectedNoYear = false,
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
            label: model?.displayName ??
                (brandSelectedNoModel ? 'كل الموديلات' : 'الموديل'),
            active: model != null || brandSelectedNoModel,
            enabled: onModelTap != null,
            onTap: onModelTap ?? () {},
          ),
          const SizedBox(width: 8),
          _Chip(
            label: year?.displayName ??
                (modelSelectedNoYear ? 'كل السنوات' : 'السنة'),
            active: year != null || modelSelectedNoYear,
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

  /// When provided, a "عرض الكل" tile appears at the top of the list.
  /// Tapping it calls this callback then closes the sheet (pops null).
  final VoidCallback? onViewAll;

  /// Explains what "عرض الكل" does (e.g. all ads for this brand).
  final String? viewAllSubtitle;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.labelOf,
    this.scrollController,
    this.onViewAll,
    this.viewAllSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasViewAll = onViewAll != null;
    // Total list count: optional "عرض الكل" row + actual items
    final itemCount = items.length + (hasViewAll ? 1 : 0);

    return Column(
      children: [
        // Handle bar
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
        if (items.isEmpty && !hasViewAll)
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
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // ── "عرض الكل" row (index 0 when hasViewAll) ─────────────
                if (hasViewAll && index == 0) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.all_inclusive_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'عرض الكل',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          viewAllSubtitle ??
                              'عرض جميع الإعلانات بدون تحديد لهذا الفلتر',
                          style: AppTextStyles.caption.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        onTap: () {
                          onViewAll!();
                          Navigator.of(context).pop();
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }

                // ── Regular item ─────────────────────────────────────────
                final itemIndex = hasViewAll ? index - 1 : index;
                final item = items[itemIndex];
                final isSelected = item == selected;
                return ListTile(
                  title: Text(
                    labelOf(item),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primaryColor
                          : context.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
// Ad Card — redesigned
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
    final isNew = ad.condition == 'new';

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: context.inputBorderColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero image with overlays ───────────────────────────────
              SizedBox(
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image carousel
                    ColoredBox(
                      color: context.surfaceBg,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pageCount,
                        physics: const PageScrollPhysics(),
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        itemBuilder: (_, index) {
                          final url = urls.isEmpty ? null : urls[index];
                          return url != null
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => _imgPlaceholder(context),
                                  errorWidget: (_, __, ___) =>
                                      _imgPlaceholder(context),
                                )
                              : _imgPlaceholder(context);
                        },
                      ),
                    ),

                    // Bottom gradient for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 90,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.62),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Condition badge (top-right on image) ───────────
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isNew
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1E3A5F),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNew
                                  ? Icons.fiber_new_rounded
                                  : Icons.history_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ad.conditionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Image counter (top-left) ───────────────────────
                    if (urls.length > 1)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${_pageIndex + 1}/${urls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Price badge (bottom-left on image) ─────────────
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ad.priceFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (ad.isNegotiable) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'قابل',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Dot indicators (bottom-center) ─────────────────
                    if (urls.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            math.min(urls.length, 6),
                            (i) {
                              final active = i == _pageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2.5),
                                width: active ? 16 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Info section ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      ad.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        fontSize: 17,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Brand · Model · Year tags
                    _CarTags(ad: ad),
                    const SizedBox(height: 10),

                    // Location
                    if (ad.locationLabel != null &&
                        ad.locationLabel!.trim().isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 15, color: AppColors.primaryColor),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              ad.locationLabel!.trim(),
                              style: AppTextStyles.caption.copyWith(
                                color: context.textSecondary,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Divider ────────────────────────────────────────
                    Divider(
                      height: 1,
                      color: context.inputBorderColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 10),

                    // ── Seller strip ───────────────────────────────────
                    _SellerStrip(ad: ad),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) {
    return Container(
      color: context.surfaceBg,
      child: Center(
        child: Icon(Icons.directions_car_outlined,
            size: 48, color: context.textHint),
      ),
    );
  }
}

// ── Car tags (Brand · Model · Year) ──────────────────────────────────────────

class _CarTags extends StatelessWidget {
  final AdModel ad;

  const _CarTags({required this.ad});

  @override
  Widget build(BuildContext context) {
    final tags = <String>[];
    final brand = ad.brand?.name?.trim();
    final model = ad.carModel?.name?.trim();
    final year = ad.year?.name?.trim();

    if (brand != null && brand.isNotEmpty) tags.add(brand);
    if (model != null && model.isNotEmpty) tags.add(model);
    if (year != null && year.isNotEmpty) tags.add(year);

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Seller strip ─────────────────────────────────────────────────────────────

class _SellerStrip extends StatelessWidget {
  final AdModel ad;

  const _SellerStrip({required this.ad});

  @override
  Widget build(BuildContext context) {
    final seller = ad.user;
    final name = seller?.displayName ?? '';
    final avatarUrl = seller?.avatarUrl;
    final isVerified = seller?.isVerified ?? false;

    return Row(
      children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.surfaceBg,
            border: Border.all(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.5)
                  : context.inputBorderColor,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _avatarFallback(context),
                    errorWidget: (_, __, ___) => _avatarFallback(context),
                  )
                : _avatarFallback(context),
          ),
        ),
        const SizedBox(width: 9),

        // Name + verified
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name.isNotEmpty ? name : 'بائع',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.primaryColor),
              ],
            ],
          ),
        ),

        // Views count
        if (ad.viewsCount != null && ad.viewsCount! > 0) ...[
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 14, color: context.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${ad.viewsCount}',
                style: AppTextStyles.caption.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],

        // Arrow
        const SizedBox(width: 6),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 13, color: AppColors.primaryColor),
        ),
      ],
    );
  }

  Widget _avatarFallback(BuildContext context) {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Icon(Icons.storefront_outlined,
          size: 18, color: AppColors.primaryColor),
    );
  }
}
