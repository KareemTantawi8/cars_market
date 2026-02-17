import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/search_requests_repository.dart';

/// Search Requests State
abstract class SearchRequestsState {}

class SearchRequestsInitial extends SearchRequestsState {}

class SearchRequestsLoading extends SearchRequestsState {}

class SearchRequestsSuccess extends SearchRequestsState {
  final Map<String, dynamic> response;
  SearchRequestsSuccess(this.response);
}

class SearchRequestsError extends SearchRequestsState {
  final String message;
  SearchRequestsError(this.message);
}

class MySearchRequestsLoaded extends SearchRequestsState {
  final List<Map<String, dynamic>> requests;
  MySearchRequestsLoaded(this.requests);
}

/// Search Requests Cubit
class SearchRequestsCubit extends Cubit<SearchRequestsState> {
  final SearchRequestsRepository _repository;

  SearchRequestsCubit({SearchRequestsRepository? repository})
      : _repository = repository ?? SearchRequestsRepository(),
        super(SearchRequestsInitial());

  /// Create a new search request
  Future<void> createSearchRequest({
    required int brandId,
    required int modelId,
    required int governorateId,
    required String partText,
    String? notes,
  }) async {
    emit(SearchRequestsLoading());
    try {
      final response = await _repository.createSearchRequest(
        brandId: brandId,
        modelId: modelId,
        governorateId: governorateId,
        partText: partText,
        notes: notes,
      );
      emit(SearchRequestsSuccess(response));
    } catch (e) {
      emit(SearchRequestsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Get my search requests
  Future<void> getMySearchRequests() async {
    emit(SearchRequestsLoading());
    try {
      final requests = await _repository.getMySearchRequests();
      emit(MySearchRequestsLoaded(requests));
    } catch (e) {
      emit(SearchRequestsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Get search request details
  Future<Map<String, dynamic>?> getSearchRequestDetails(int requestId) async {
    try {
      return await _repository.getSearchRequestDetails(requestId);
    } catch (e) {
      emit(SearchRequestsError(e.toString().replaceAll('Exception: ', '')));
      return null;
    }
  }
}

