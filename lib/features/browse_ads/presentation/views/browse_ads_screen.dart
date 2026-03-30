import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../home/data/models/category_models.dart';
import '../../../home/presentation/cubit/category_cubit.dart';
import '../../../ads/data/models/ad_model.dart';
import '../../../ads/presentation/cubit/ads_list_cubit.dart';

/// Step in the browse flow: brands → models → ads
enum _BrowseStep { brands, models, ads }

/// Browse Ads tab: brands → models → ads
class BrowseAdsScreen extends StatefulWidget {
  const BrowseAdsScreen({super.key});

  @override
  State<BrowseAdsScreen> createState() => _BrowseAdsScreenState();
}

class _BrowseAdsScreenState extends State<BrowseAdsScreen> {
  _BrowseStep _step = _BrowseStep.brands;
  BrandModel? _selectedBrand;
  CarModelModel? _selectedModel;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cat = context.read<CategoryCubit>().state;
      if (cat is CategoryInitial) {
        context.read<CategoryCubit>().loadInitialData();
      } else if (cat is CategoryLoaded && cat.brands.isEmpty) {
        context.read<CategoryCubit>().loadBrands();
      }
    });
  }

  void _onBrandTap(BrandModel brand) {
    setState(() {
      _selectedBrand = brand;
      _step = _BrowseStep.models;
      _stepIndex++;
    });
    context.read<CategoryCubit>().loadModels(brand.id);
  }

  void _onModelTap(CarModelModel model) {
    setState(() {
      _selectedModel = model;
      _step = _BrowseStep.ads;
      _stepIndex++;
    });
    context.read<AdsListCubit>().loadAds(modelId: model.id);
  }

  void _onBack() {
    if (_step == _BrowseStep.ads) {
      setState(() {
        _step = _BrowseStep.models;
        _selectedModel = null;
        _stepIndex--;
      });
    } else if (_step == _BrowseStep.models) {
      setState(() {
        _step = _BrowseStep.brands;
        _selectedBrand = null;
        _selectedModel = null;
        _stepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _step == _BrowseStep.brands
                ? 'تصفح الإعلانات'
                : _step == _BrowseStep.models
                    ? (_selectedBrand?.displayName ?? 'اختر الموديل')
                    : (_selectedModel?.displayName ?? 'الإعلانات'),
            key: ValueKey<_BrowseStep>(_step),
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step != _BrowseStep.brands
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary),
                onPressed: _onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_stepIndex),
            child: _step == _BrowseStep.brands
                ? _buildBrandsList()
                : _step == _BrowseStep.models
                    ? _buildModelsList()
                    : _buildAdsList(),
          ),
        ),
      ),
    );
  }

  // ── Brands ────────────────────────────────────────────────────────────────

  Widget _buildBrandsList() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading && state.loadingType == 'brands') {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError && state.errorType == 'brands') {
          return _buildError(
            state.message,
            () => context.read<CategoryCubit>().loadBrands(),
          );
        }
        List<BrandModel> brands = [];
        if (state is CategoryLoaded) brands = state.brands;
        if (brands.isEmpty) {
          return Center(
            child: Text('لا توجد ماركات',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          itemCount: brands.length,
          itemBuilder: (context, index) => _BrandTile(
            brand: brands[index],
            index: index,
            onTap: () => _onBrandTap(brands[index]),
          ),
        );
      },
    );
  }

  // ── Models ────────────────────────────────────────────────────────────────

  Widget _buildModelsList() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading && state.loadingType == 'models') {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError && state.errorType == 'models') {
          return _buildError(
            state.message,
            () {
              if (_selectedBrand != null) {
                context.read<CategoryCubit>().loadModels(_selectedBrand!.id);
              }
            },
          );
        }
        List<CarModelModel> models = [];
        if (state is CategoryLoaded) models = state.models;
        if (models.isEmpty) {
          return Center(
            child: Text('لا توجد موديلات لهذه الماركة',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: models.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModelTile(
              model: models[index],
              index: index,
              onTap: () => _onModelTap(models[index]),
            ),
          ),
        );
      },
    );
  }

  // ── Ads ───────────────────────────────────────────────────────────────────

  Widget _buildAdsList() {
    return BlocConsumer<AdsListCubit, AdsListState>(
      listener: (context, state) {
        if (state is AdsListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is AdsListInitial || state is AdsListLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (state is AdsListError) {
          return _buildError(
            state.message,
            () {
              if (_selectedModel != null) {
                context.read<AdsListCubit>().loadAds(modelId: _selectedModel!.id);
              }
            },
          );
        }
        if (state is AdsListLoaded) {
          final ads = state.ads;
          if (ads.isEmpty) {
            return Center(
              child: Text('لا توجد إعلانات لهذا الموديل',
                  style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: ads.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AdCard(ad: ads[index], index: index),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Tile – staggered entrance + press scale
// ─────────────────────────────────────────────────────────────────────────────

class _BrandTile extends StatefulWidget {
  final BrandModel brand;
  final int index;
  final VoidCallback onTap;

  const _BrandTile({required this.brand, required this.index, required this.onTap});

  @override
  State<_BrandTile> createState() => _BrandTileState();
}

class _BrandTileState extends State<_BrandTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  String? get _imageUrl {
    final path = widget.brand.logo;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    // Staggered entrance: each tile cascades 55 ms after the previous (capped)
    final staggerMs = (widget.index * 55).clamp(0, 550);
    final totalMs = 380 + staggerMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Apply individual delay: animation only starts after stagger fraction
        final delayFrac = staggerMs / totalMs;
        final animated = ((value - delayFrac) / (1.0 - delayFrac)).clamp(0.0, 1.0);
        return Opacity(
          opacity: animated,
          child: Transform.translate(
            offset: Offset(0, 28.0 * (1.0 - animated)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.inputBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => _placeholder(context),
                        errorWidget: (_, __, ___) => _placeholder(context),
                      )
                    : _placeholder(context),
              ),
            ),
            // Label bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.07),
                border: Border(
                  top: BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.12),
                  ),
                ),
              ),
              child: Text(
                widget.brand.displayName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.directions_car_outlined,
        size: 44,
        color: AppColors.primaryColor.withOpacity(0.25),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model Tile – staggered slide-in + press scale
// ─────────────────────────────────────────────────────────────────────────────

class _ModelTile extends StatefulWidget {
  final CarModelModel model;
  final int index;
  final VoidCallback onTap;

  const _ModelTile({required this.model, required this.index, required this.onTap});

  @override
  State<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends State<_ModelTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final staggerMs = (widget.index * 40).clamp(0, 480);
    final totalMs = 350 + staggerMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayFrac = staggerMs / totalMs;
        final animated = ((value - delayFrac) / (1.0 - delayFrac)).clamp(0.0, 1.0);
        return Opacity(
          opacity: animated,
          child: Transform.translate(
            offset: Offset(18.0 * (1.0 - animated), 0),
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.inputBorderColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  widget.model.displayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ad Card – staggered fade-up + press scale
// ─────────────────────────────────────────────────────────────────────────────

class _AdCard extends StatefulWidget {
  final AdModel ad;
  final int index;

  const _AdCard({required this.ad, required this.index});

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  bool _pressed = false;

  String? get _imageUrl {
    final path = widget.ad.firstImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    final staggerMs = (widget.index * 45).clamp(0, 450);
    final totalMs = 380 + staggerMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayFrac = staggerMs / totalMs;
        final animated = ((value - delayFrac) / (1.0 - delayFrac)).clamp(0.0, 1.0);
        return Opacity(
          opacity: animated,
          child: Transform.translate(
            offset: Offset(0, 16.0 * (1.0 - animated)),
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            Navigator.pushNamed(
              context,
              AppRoutes.adDetails,
              arguments: {'adId': widget.ad.id},
            );
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 120,
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImage(context),
                    Expanded(child: _buildInfo(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 120,
      child: _imageUrl != null
          ? CachedNetworkImage(
              imageUrl: _imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(context),
              errorWidget: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.ad.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.ad.priceFormatted,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.surfaceBg,
      child: Center(
        child: Icon(Icons.directions_car_outlined, size: 40, color: context.textHint),
      ),
    );
  }
}
