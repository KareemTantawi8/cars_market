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

  /// Load initial data (brands and governorates)
  Future<void> loadInitialData() async {
    emit(const CategoryLoading('initial'));

    try {
      // Load brands and governorates in parallel
      final results = await Future.wait([
        _categoryRepository.getBrands(),
        _categoryRepository.getGovernorates(),
      ]);

      final brands = results[0] as List<BrandModel>;
      final governorates = results[1] as List<GovernorateModel>;

      emit(CategoryLoaded(
        brands: brands,
        governorates: governorates,
      ));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'initial'));
    }
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
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(const CategoryLoading('models'));
    }
    try {
      final models = await _categoryRepository.getModelsByBrand(brandId);

      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(
          models: models,
          years: [], // Clear years when brand changes
          clearSelectedModel: true,
          clearSelectedYear: true,
        ));
      } else {
        emit(CategoryLoaded(models: models));
      }
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', ''), 'models'));
    }
  }

  /// Load years for selected model
  Future<void> loadYears(int modelId) async {
    final currentState = state;

    try {
      final years = await _categoryRepository.getYearsByModel(modelId);

      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(
          years: years,
          clearSelectedYear: true,
        ));
      } else {
        emit(CategoryLoaded(years: years));
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

