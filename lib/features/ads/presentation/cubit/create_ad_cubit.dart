import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/ads_repository.dart';
import '../../data/models/ad_model.dart';

abstract class CreateAdState extends Equatable {
  const CreateAdState();
  @override
  List<Object?> get props => [];
}

class CreateAdInitial extends CreateAdState {}

class CreateAdSubmitting extends CreateAdState {}

class CreateAdSuccess extends CreateAdState {
  final AdModel ad;
  const CreateAdSuccess(this.ad);
  @override
  List<Object?> get props => [ad];
}

class CreateAdError extends CreateAdState {
  final String message;
  const CreateAdError(this.message);
  @override
  List<Object?> get props => [message];
}

class CreateAdCubit extends Cubit<CreateAdState> {
  final AdsRepository _repo = AdsRepository();

  CreateAdCubit() : super(CreateAdInitial());

  Future<void> createAd({
    required String title,
    String? description,
    required int brandId,
    int? modelId,
    int? yearId,
    required String condition,
    double? price,
    bool isNegotiable = false,
    bool isPhoneVisible = true,
    List<File>? imageFiles,
    String? expiresAt,
  }) async {
    emit(CreateAdSubmitting());
    try {
      final ad = await _repo.createAd(
        title: title,
        description: description,
        brandId: brandId,
        modelId: modelId,
        yearId: yearId,
        condition: condition,
        price: price,
        isNegotiable: isNegotiable,
        isPhoneVisible: isPhoneVisible,
        imageFiles: imageFiles,
        expiresAt: expiresAt,
      );
      emit(CreateAdSuccess(ad));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(CreateAdError(msg));
    }
  }

  /// PUT /ads/:id - Update ad (optional fields)
  Future<void> updateAd(
    int id, {
    String? title,
    String? description,
    int? brandId,
    int? modelId,
    int? yearId,
    String? condition,
    double? price,
    bool? isNegotiable,
    bool? isPhoneVisible,
    bool? isActive,
    List<File>? imageFiles,
    String? expiresAt,
  }) async {
    emit(CreateAdSubmitting());
    try {
      final ad = await _repo.updateAd(
        id,
        title: title,
        description: description,
        brandId: brandId,
        modelId: modelId,
        yearId: yearId,
        condition: condition,
        price: price,
        isNegotiable: isNegotiable,
        isPhoneVisible: isPhoneVisible,
        isActive: isActive,
        imageFiles: imageFiles,
        expiresAt: expiresAt,
      );
      emit(CreateAdSuccess(ad));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(CreateAdError(msg));
    }
  }

  void reset() => emit(CreateAdInitial());
}
