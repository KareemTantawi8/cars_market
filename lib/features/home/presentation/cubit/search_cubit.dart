import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/models/search_request_model.dart';
import '../../data/models/search_response_model.dart';

/// Search State
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {}

/// Loading state
class SearchLoading extends SearchState {}

/// Success state
class SearchSuccess extends SearchState {
  final SearchResponseModel response;
  final SearchRequestModel request;

  const SearchSuccess(this.response, this.request);

  @override
  List<Object?> get props => [response, request];
}

/// Error state
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Search Cubit
class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _searchRepository;

  SearchCubit({SearchRepository? searchRepository})
      : _searchRepository = searchRepository ?? SearchRepository(),
        super(SearchInitial());

  /// Search for suppliers with new model (using IDs)
  Future<void> searchSuppliers({
    String? partName,
    int? brandId,
    int? modelId,
    int? yearId,
    int? governorateId,
    String? brandName,
    String? modelName,
    String? yearName,
    String? governorateName,
  }) async {
    emit(SearchLoading());

    try {
      // Create request model
      final request = SearchRequestModel(
        partName: partName,
        brandId: brandId,
        modelId: modelId,
        yearId: yearId,
        governorateId: governorateId,
        brandName: brandName,
        modelName: modelName,
        yearName: yearName,
        governorateName: governorateName,
      );

      // Call API
      final response = await _searchRepository.searchSuppliers(request);

      emit(SearchSuccess(response, request));
    } catch (e) {
      emit(SearchError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(SearchInitial());
  }

  /// Clear search results and return to initial state
  void clearSearch() {
    emit(SearchInitial());
  }
}

