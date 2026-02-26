import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ads_repository.dart';
import '../../data/models/ad_model.dart';

abstract class AdDetailsState extends Equatable {
  const AdDetailsState();
  @override
  List<Object?> get props => [];
}

class AdDetailsInitial extends AdDetailsState {}

class AdDetailsLoading extends AdDetailsState {}

class AdDetailsLoaded extends AdDetailsState {
  final AdModel ad;
  const AdDetailsLoaded(this.ad);
  @override
  List<Object?> get props => [ad];
}

class AdDetailsError extends AdDetailsState {
  final String message;
  const AdDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdDetailsCubit extends Cubit<AdDetailsState> {
  final AdsRepository _repo = AdsRepository();

  AdDetailsCubit() : super(AdDetailsInitial());

  Future<void> loadAd(int id) async {
    emit(AdDetailsLoading());
    try {
      final ad = await _repo.getAdById(id);
      emit(AdDetailsLoaded(ad));
    } catch (e) {
      emit(AdDetailsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
