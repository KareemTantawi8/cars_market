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

/// Browse Ads tab: show all brands → on tap show models → on tap show ads for that model
class BrowseAdsScreen extends StatefulWidget {
  const BrowseAdsScreen({super.key});

  @override
  State<BrowseAdsScreen> createState() => _BrowseAdsScreenState();
}

class _BrowseAdsScreenState extends State<BrowseAdsScreen> {
  _BrowseStep _step = _BrowseStep.brands;
  BrandModel? _selectedBrand;
  CarModelModel? _selectedModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cat = context.read<CategoryCubit>().state;
      if (cat is! CategoryLoaded || cat.brands.isEmpty) {
        context.read<CategoryCubit>().loadBrands();
      }
    });
  }

  void _onBrandTap(BrandModel brand) {
    setState(() {
      _selectedBrand = brand;
      _step = _BrowseStep.models;
    });
    context.read<CategoryCubit>().loadModels(brand.id);
  }

  void _onModelTap(CarModelModel model) {
    setState(() {
      _selectedModel = model;
      _step = _BrowseStep.ads;
    });
    context.read<AdsListCubit>().loadAds(modelId: model.id);
  }

  void _onBack() {
    if (_step == _BrowseStep.ads) {
      setState(() {
        _step = _BrowseStep.models;
        _selectedModel = null;
      });
    } else if (_step == _BrowseStep.models) {
      setState(() {
        _step = _BrowseStep.brands;
        _selectedBrand = null;
        _selectedModel = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _step == _BrowseStep.brands
              ? 'تصفح الإعلانات'
              : _step == _BrowseStep.models
                  ? (_selectedBrand?.displayName ?? 'اختر الموديل')
                  : (_selectedModel?.displayName ?? 'الإعلانات'),
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
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
        child: _step == _BrowseStep.brands
            ? _buildBrandsList()
            : _step == _BrowseStep.models
                ? _buildModelsList()
                : _buildAdsList(),
      ),
    );
  }

  Widget _buildBrandsList() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading && state.loadingType == 'brands') {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError && state.errorType == 'brands') {
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
                  onPressed: () => context.read<CategoryCubit>().loadBrands(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        List<BrandModel> brands = [];
        if (state is CategoryLoaded) {
          brands = state.brands;
        }
        if (brands.isEmpty) {
          return Center(
            child: Text(
              'لا توجد ماركات',
              style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: brands.length,
          itemBuilder: (context, index) => _BrandTile(
            brand: brands[index],
            onTap: () => _onBrandTap(brands[index]),
          ),
        );
      },
    );
  }

  Widget _buildModelsList() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading && state.loadingType == 'models') {
          return const Center(child: LoadingIndicator());
        }
        if (state is CategoryError && state.errorType == 'models') {
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
                  onPressed: () {
                    if (_selectedBrand != null) {
                      context.read<CategoryCubit>().loadModels(_selectedBrand!.id);
                    }
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        List<CarModelModel> models = [];
        if (state is CategoryLoaded) {
          models = state.models;
        }
        if (models.isEmpty) {
          return Center(
            child: Text(
              'لا توجد موديلات لهذه الماركة',
              style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: models.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModelTile(
              model: models[index],
              onTap: () => _onModelTap(models[index]),
            ),
          ),
        );
      },
    );
  }

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
                  onPressed: () {
                    if (_selectedModel != null) {
                      context.read<AdsListCubit>().loadAds(modelId: _selectedModel!.id);
                    }
                  },
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
              child: Text(
                'لا توجد إعلانات لهذا الموديل',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: ads.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BrowseAdCard(ad: ads[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BrandTile extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;

  const _BrandTile({required this.brand, required this.onTap});

  String? get _imageUrl {
    final path = brand.logo;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                brand.displayName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
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
      child: Icon(Icons.directions_car_outlined, size: 48, color: context.textHint),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final CarModelModel model;
  final VoidCallback onTap;

  const _ModelTile({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          model.displayName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.textHint),
        onTap: onTap,
      ),
    );
  }
}

class _BrowseAdCard extends StatelessWidget {
  final AdModel ad;

  const _BrowseAdCard({required this.ad});

  String? get _imageUrl {
    final path = ad.firstImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.adDetails,
        arguments: {'adId': ad.id},
      ),
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
            ad.title,
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
              ad.priceFormatted,
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
