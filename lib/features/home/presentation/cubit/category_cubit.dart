import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/category_models.dart';

/// Category State
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryInitial extends CategoryState {}

/// Loading state
class CategoryLoading extends CategoryState {
  final String loadingType; // 'brands', 'models', 'years', 'governorates'

  const CategoryLoading(this.loadingType);

  @override
  List<Object?> get props => [loadingType];
}

/// Categories loaded state
class CategoryLoaded extends CategoryState {
  final List<BrandModel> brands;
  final List<CarModelModel> models;
  final List<YearModel> years;
  final List<GovernorateModel> governorates;
  final BrandModel? selectedBrand;
  final CarModelModel? selectedModel;
  final YearModel? selectedYear;
  final GovernorateModel? selectedGovernorate;

  const CategoryLoaded({
    this.brands = const [],
    this.models = const [],
    this.years = const [],
    this.governorates = const [],
    this.selectedBrand,
    this.selectedModel,
    this.selectedYear,
    this.selectedGovernorate,
  });

  CategoryLoaded copyWith({
    List<BrandModel>? brands,
    List<CarModelModel>? models,
    List<YearModel>? years,
    List<GovernorateModel>? governorates,
    BrandModel? selectedBrand,
    CarModelModel? selectedModel,
    YearModel? selectedYear,
    GovernorateModel? selectedGovernorate,
    bool clearSelectedBrand = false,
    bool clearSelectedModel = false,
    bool clearSelectedYear = false,
    bool clearSelectedGovernorate = false,
  }) {
    return CategoryLoaded(
      brands: brands ?? this.brands,
      models: models ?? this.models,
      years: years ?? this.years,
      governorates: governorates ?? this.governorates,
      selectedBrand: clearSelectedBrand ? null : (selectedBrand ?? this.selectedBrand),
      selectedModel: clearSelectedModel ? null : (selectedModel ?? this.selectedModel),
      selectedYear: clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      selectedGovernorate: clearSelectedGovernorate ? null : (selectedGovernorate ?? this.selectedGovernorate),
    );
  }

  @override
  List<Object?> get props => [
        brands,
        models,
        years,
        governorates,
        selectedBrand,
        selectedModel,
        selectedYear,
        selectedGovernorate,
      ];
}

/// Error state
class CategoryError extends CategoryState {
  final String message;
  final String errorType; // 'brands', 'models', 'years', 'governorates'

  const CategoryError(this.message, this.errorType);

  @override
  List<Object?> get props => [message, errorType];
}

/// Category Cubit - Manages categories (brands, models, years, governorates)
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryCubit({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(CategoryInitial());

  /// Load brands and governorates.
  ///
  /// When [withSearchFormDefaults] is true (home search form), also loads
  /// models/years and pre-selects brand/model/year/governorate.
  /// When false (e.g. register), emits as soon as brands + governorates are
  /// ready so pickers work without extra network or cubit selections.
  Future<void> loadInitialData({bool withSearchFormDefaults = true}) async {
    emit(const CategoryLoading('initial'));

    try {
      // Load brands and governorates in parallel
      final results = await Future.wait([
        _categoryRepository.getBrands(),
        _categoryRepository.getGovernorates(),
      ]);

      final brands = results[0] as List<BrandModel>;
      final governorates = results[1] as List<GovernorateModel>;

      if (!withSearchFormDefaults) {
        // Still pick a default governorate (Cairo) for convenience —
        // brand/model/year are left blank for the user to choose freely.
        final selectedGovernorate = _pickDefaultGovernorate(governorates);
        emit(CategoryLoaded(
          brands: brands,
          governorates: governorates,
          selectedGovernorate: selectedGovernorate,
        ));
        return;
      }

      final selectedGovernorate = _pickDefaultGovernorate(governorates);
      final selectedBrand = _pickDefaultBrand(brands);

      List<CarModelModel> models = [];
      List<YearModel> years = [];
      CarModelModel? selectedModel;
      YearModel? selectedYear;

      if (selectedBrand != null) {
        try {
          models = await _categoryRepository.getModelsByBrand(selectedBrand.id);
          selectedModel = _pickDefaultModel(models);
          if (selectedModel != null) {
            years = await _categoryRepository.getYearsByModel(selectedModel.id);
            selectedYear = _pickDefaultYear(years);
          }
        } catch (_) {
          // Keep lists/selections partial; user can pick manually
        }
      }

      emit(CategoryLoaded(
        brands: brands,
        models: models,
        years: years,
        governorates: governorates,
        selectedBrand: selectedBrand,
        selectedModel: selectedModel,
        selectedYear: selectedYear,
        selectedGovernorate: selectedGovernorate,
      ));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'initial'));
    }
  }

  GovernorateModel? _pickDefaultGovernorate(List<GovernorateModel> list) {
    if (list.isEmpty) return null;
    for (final g in list) {
      final slug = g.slug?.toLowerCase() ?? '';
      if (g.displayName.contains('القاهرة') ||
          slug == 'cairo' ||
          slug.contains('cairo')) {
        return g;
      }
    }
    return list.first;
  }

  BrandModel? _pickDefaultBrand(List<BrandModel> brands) {
    if (brands.isEmpty) return null;
    bool matches(BrandModel b, String needle) {
      final n = needle.toLowerCase();
      return b.name.toLowerCase().contains(n) ||
          (b.nameAr ?? '').toLowerCase().contains(n);
    }

    for (final b in brands) {
      if (matches(b, 'تويوتا') || matches(b, 'toyota')) return b;
    }
    return brands.first;
  }

  CarModelModel? _pickDefaultModel(List<CarModelModel> models) {
    if (models.isEmpty) return null;
    bool matches(CarModelModel m, String needle) {
      final n = needle.toLowerCase();
      return m.name.toLowerCase().contains(n) ||
          (m.nameAr ?? '').toLowerCase().contains(n);
    }

    for (final m in models) {
      if (matches(m, 'كورولا') || matches(m, 'corolla')) return m;
    }
    return models.first;
  }

  YearModel? _pickDefaultYear(List<YearModel> years) {
    if (years.isEmpty) return null;
    final target = DateTime.now().year;
    for (final y in years) {
      if (y.yearInt == target) return y;
    }
    YearModel? best;
    var bestVal = -1;
    for (final y in years) {
      final yi = y.yearInt;
      if (yi != null && yi > bestVal) {
        bestVal = yi;
        best = y;
      }
    }
    return best ?? years.first;
  }

  /// Load brands
  Future<void> loadBrands() async {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(const CategoryLoading('brands'));
    }

    try {
      final brands = await _categoryRepository.getBrands();

      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(brands: brands));
      } else {
        emit(CategoryLoaded(brands: brands));
      }
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'brands'));
    }
  }

  /// Load models for selected brand
  Future<void> loadModels(int brandId) async {
    try {
      final models = await _categoryRepository.getModelsByBrand(brandId);
      final latest = state;
      if (latest is CategoryLoaded && latest.selectedBrand?.id == brandId) {
        emit(latest.copyWith(
          models: models,
          years: [],
          clearSelectedModel: true,
          clearSelectedYear: true,
        ));
      }
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'models'));
    }
  }

  /// Load years for selected model
  Future<void> loadYears(int modelId) async {
    try {
      final years = await _categoryRepository.getYearsByModel(modelId);
      final latest = state;
      if (latest is CategoryLoaded && latest.selectedModel?.id == modelId) {
        // Do not clear selectedYear here — selectModel already cleared it; clearing again
        // with a stale snapshot could wipe the user's pick if requests complete out of order.
        emit(latest.copyWith(years: years));
      }
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'years'));
    }
  }

  /// Load governorates
  Future<void> loadGovernorates() async {
    final currentState = state;

    try {
      final governorates = await _categoryRepository.getGovernorates();

      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(governorates: governorates));
      } else {
        emit(CategoryLoaded(governorates: governorates));
      }
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'governorates'));
    }
  }

  /// Select a brand
  void selectBrand(BrandModel brand) {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(
        selectedBrand: brand,
        models: [], // Clear models
        years: [], // Clear years
        clearSelectedModel: true,
        clearSelectedYear: true,
      ));
      // Load models for selected brand
      loadModels(brand.id);
    }
  }

  /// Select a model
  void selectModel(CarModelModel model) {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(
        selectedModel: model,
        years: [], // Clear years
        clearSelectedYear: true,
      ));
      // Load years for selected model
      loadYears(model.id);
    }
  }

  /// Select a year
  void selectYear(YearModel year) {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(selectedYear: year));
    }
  }

  /// Select a governorate
  void selectGovernorate(GovernorateModel governorate) {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(selectedGovernorate: governorate));
    }
  }

  /// Clear all selections
  void clearSelections() {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(
        models: [],
        years: [],
        clearSelectedBrand: true,
        clearSelectedModel: true,
        clearSelectedYear: true,
        clearSelectedGovernorate: true,
      ));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(CategoryInitial());
  }
}

