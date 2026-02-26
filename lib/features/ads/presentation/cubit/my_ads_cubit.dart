import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ads_repository.dart';
import '../../data/models/ad_model.dart';

/// My Ads list state
abstract class MyAdsState extends Equatable {
  const MyAdsState();
  @override
  List<Object?> get props => [];
}

class MyAdsInitial extends MyAdsState {}

class MyAdsLoading extends MyAdsState {}

class MyAdsLoaded extends MyAdsState {
  final List<AdModel> ads;
  final int currentPage;
  final bool hasMore;

  const MyAdsLoaded({
    required this.ads,
    this.currentPage = 1,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [ads, currentPage, hasMore];
}

class MyAdsError extends MyAdsState {
  final String message;
  const MyAdsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit for GET /my-ads - current user's ads
class MyAdsCubit extends Cubit<MyAdsState> {
  final AdsRepository _repo = AdsRepository();

  MyAdsCubit() : super(MyAdsInitial());

  Future<void> loadMyAds({int page = 1}) async {
    if (page == 1) emit(MyAdsLoading());
    try {
      final result = await _repo.getMyAds(page: page, perPage: 20);
      final existing = state is MyAdsLoaded ? (state as MyAdsLoaded).ads : <AdModel>[];
      final ads = page == 1 ? result.data : [...existing, ...result.data];
      emit(MyAdsLoaded(
        ads: ads,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(MyAdsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> refresh() => loadMyAds(page: 1);

  /// Load next page (for pagination)
  Future<void> loadMore() async {
    final s = state;
    if (s is! MyAdsLoaded || !s.hasMore) return;
    await loadMyAds(page: s.currentPage + 1);
  }

  /// Delete ad and refresh list
  Future<void> deleteAd(int id) async {
    try {
      await _repo.deleteAd(id);
      await loadMyAds(page: 1);
    } catch (_) {
      rethrow;
    }
  }
}
