import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ads_repository.dart';
import '../../data/models/ad_model.dart';

abstract class AdsListState extends Equatable {
  const AdsListState();
  @override
  List<Object?> get props => [];
}

class AdsListInitial extends AdsListState {}

class AdsListLoading extends AdsListState {}

class AdsListLoaded extends AdsListState {
  final List<AdModel> ads;
  final int currentPage;
  final bool hasMore;

  const AdsListLoaded({
    required this.ads,
    this.currentPage = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [ads, currentPage, hasMore];
}

class AdsListError extends AdsListState {
  final String message;
  const AdsListError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdsListCubit extends Cubit<AdsListState> {
  final AdsRepository _repo = AdsRepository();

  AdsListCubit() : super(AdsListInitial());

  Future<void> loadAds({
    int? brandId,
    int? modelId,
    int? yearId,
    String? condition,
    String? search,
    int page = 1,
  }) async {
    if (page == 1) emit(AdsListLoading());
    try {
      final result = await _repo.getAds(
        brandId: brandId,
        modelId: modelId,
        yearId: yearId,
        condition: condition,
        search: search,
        page: page,
        perPage: 20,
      );
      final existing = state is AdsListLoaded ? (state as AdsListLoaded).ads : <AdModel>[];
      final ads = page == 1 ? result.data : [...existing, ...result.data];
      emit(AdsListLoaded(
        ads: ads,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(AdsListError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh({int? brandId, int? modelId, int? yearId, String? condition, String? search}) =>
      loadAds(page: 1, brandId: brandId, modelId: modelId, yearId: yearId, condition: condition, search: search);

  Future<void> loadMore({
    int? brandId,
    int? modelId,
    int? yearId,
    String? condition,
    String? search,
  }) async {
    final s = state;
    if (s is! AdsListLoaded || !s.hasMore) return;
    await loadAds(
      page: s.currentPage + 1,
      brandId: brandId,
      modelId: modelId,
      yearId: yearId,
      condition: condition,
      search: search,
    );
  }
}
