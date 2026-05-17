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

/// Browse Ads flow:
/// 1) brand grid (تصفح الإعلانات)
/// 2) choose model
/// 3) filtered results
class BrowseAdsScreen extends StatefulWidget {
  const BrowseAdsScreen({
    super.key,
    this.isEmbeddedInShell = false,
    this.onBackToHome,
  });

  /// When true, system back on brand step goes to home tab (see [HomeScreen]).
  final bool isEmbeddedInShell;
  final VoidCallback? onBackToHome;

  @override
  State<BrowseAdsScreen> createState() => BrowseAdsScreenState();
}

class BrowseAdsScreenState extends State<BrowseAdsScreen> {
  _BrowseStep _step = _BrowseStep.brand;
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
      _step = _BrowseStep.brand;
      _brand = null;
      _model = null;
      _year = null;
      _condition = null;
    });
    context.read<CategoryCubit>().clearSelections();
    context.read<AdsListCubit>().loadAds();
  }

  /// Returns true if the back press was handled internally.
  bool handleSystemBack() {
    if (_step == _BrowseStep.brand) return false;
    setState(() {
      if (_step == _BrowseStep.results) {
        _step = _BrowseStep.model;
      } else if (_step == _BrowseStep.model) {
        _step = _BrowseStep.brand;
        _brand = null;
        _model = null;
      }
    });
    return true;
  }

  void _goBackOneStep() {
    if (handleSystemBack()) return;
    if (widget.isEmbeddedInShell) {
      widget.onBackToHome?.call();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showSearchDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text(
          'بحث في الإعلانات',
          style: AppTextStyles.headingSmall.copyWith(color: context.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.input.copyWith(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'ابحث عن قطعة أو إعلان...',
            hintStyle: AppTextStyles.inputHint,
          ),
          onSubmitted: (q) {
            Navigator.pop(ctx);
            setState(() {
              _step = _BrowseStep.results;
              _brand = null;
              _model = null;
            });
            context.read<AdsListCubit>().loadAds(search: q.trim().isEmpty ? null : q.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final q = controller.text.trim();
              Navigator.pop(ctx);
              setState(() {
                _step = _BrowseStep.results;
                _brand = null;
                _model = null;
              });
              context.read<AdsListCubit>().loadAds(search: q.isEmpty ? null : q);
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  String? _brandLogoUrl(BrandModel brand) {
    final logo = brand.logo;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http')) return logo;
    return '${AppConstants.storageBaseUrl}/$logo';
  }

  // ── old flow actions ───────────────────────────────────────────────────────

  Future<void> _selectBrand(BrandModel brand) async {
    setState(() {
      _brand = brand;
      _model = null;
      _year = null;
      _step = _BrowseStep.model;
    });
    context.read<CategoryCubit>().selectBrand(brand);
    await context.read<CategoryCubit>().loadModels(brand.id);
  }

  void _selectModel(CarModelModel? model) {
    setState(() {
      _model = model;
      _year = null;
      _step = _BrowseStep.results;
    });
    if (model == null) {
      context.read<CategoryCubit>().clearModelAndYearKeepingBrand();
    } else {
      context.read<CategoryCubit>().selectModel(model);
    }
    _applyFilters();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _step == _BrowseStep.brand ? null : _buildInnerAppBar(),
      body: _step == _BrowseStep.brand
          ? Column(
              children: [
                _buildBrowseHeader(),
                Expanded(child: _buildStepBody()),
              ],
            )
          : _buildStepBody(),
    );

    if (widget.isEmbeddedInShell) return scaffold;

    return PopScope(
      canPop: _step == _BrowseStep.brand,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackOneStep();
      },
      child: scaffold,
    );
  }

  PreferredSizeWidget _buildInnerAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: _goBackOneStep,
      ),
      title: Text(
        _step == _BrowseStep.model ? 'اختر الموديل' : 'نتائج الإعلانات',
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
    );
  }

  Widget _buildBrowseHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.search, color: context.textPrimary, size: 26),
              onPressed: _showSearchDialog,
            ),
            Expanded(
              child: Text(
                'تصفح الإعلانات',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    if (_step == _BrowseStep.brand) return _buildBrandsStep();
    if (_step == _BrowseStep.model) return _buildModelsStep();
    return const _AdsList();
  }

  Widget _buildBrandsStep() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading || state is CategoryInitial) {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError) {
          return _SelectionError(
            message: state.message,
            onRetry: () => context.read<CategoryCubit>().loadBrands(),
          );
        }
        if (state is! CategoryLoaded) return const SizedBox.shrink();

        if (state.brands.isEmpty) {
          return const _SelectionEmpty(message: 'لا توجد ماركات متاحة');
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: state.brands.length,
          itemBuilder: (context, index) {
            final brand = state.brands[index];
            final logoUrl = _brandLogoUrl(brand);
            return _BrandGridCard(
              name: brand.name,
              logoUrl: logoUrl,
              onTap: () => _selectBrand(brand),
            );
          },
        );
      },
    );
  }

  Widget _buildModelsStep() {
    if (_brand == null) {
      return const _SelectionEmpty(message: 'اختر الماركة أولاً');
    }

    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError) {
          return _SelectionError(
            message: state.message,
            onRetry: () => context.read<CategoryCubit>().loadModels(_brand!.id),
          );
        }
        if (state is! CategoryLoaded) return const SizedBox.shrink();

        final models = state.models;
        if (models.isEmpty) {
          return const _SelectionEmpty(message: 'لا توجد موديلات متاحة لهذه الماركة');
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: models.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _SelectionTile(
                label: 'عرض كل موديلات ${_brand!.displayName}',
                subtitle: 'بدون تحديد موديل',
                active: _model == null,
                onTap: () => _selectModel(null),
              );
            }
            final model = models[index - 1];
            final active = _model?.id == model.id;
            return _SelectionTile(
              label: model.displayName,
              active: active,
              onTap: () => _selectModel(model),
            );
          },
        );
      },
    );
  }
}

enum _BrowseStep { brand, model, results }

class _BrandGridCard extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final VoidCallback onTap;

  const _BrandGridCard({
    required this.name,
    required this.onTap,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.inputBorderColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: logoUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Icon(
                            Icons.directions_car_outlined,
                            size: 40,
                            color: context.textHint,
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.directions_car_outlined,
                            size: 40,
                            color: context.textHint,
                          ),
                        )
                      : Icon(
                          Icons.directions_car_outlined,
                          size: 44,
                          color: context.textHint,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool active;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primaryColor.withValues(alpha: 0.1) : context.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primaryColor : context.inputBorderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption.copyWith(color: context.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                active ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: active ? AppColors.primaryColor : context.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionEmpty extends StatelessWidget {
  final String message;
  const _SelectionEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
      ),
    );
  }
}

class _SelectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SelectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
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
