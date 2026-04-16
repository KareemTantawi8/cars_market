import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/models/user_profile_model.dart';

/// User Profile State
abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserProfileInitial extends UserProfileState {}

/// Loading state
class UserProfileLoading extends UserProfileState {}

/// Profile loaded successfully
class UserProfileLoaded extends UserProfileState {
  final UserProfileModel profile;

  const UserProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile images just uploaded successfully (show toast then treat like Loaded)
class UserProfileImagesUploaded extends UserProfileState {
  final UserProfileModel profile;

  const UserProfileImagesUploaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Error state
class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// User Profile Cubit
class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepository _userProfileRepository;

  UserProfileCubit({UserProfileRepository? userProfileRepository})
      : _userProfileRepository = userProfileRepository ?? UserProfileRepository(),
        super(UserProfileInitial());

  /// Fetch current user profile
  Future<void> fetchCurrentUserProfile() async {
    emit(UserProfileLoading());

    try {
      final profile = await _userProfileRepository.getCurrentUserProfile();
      emit(UserProfileLoaded(profile));
    } catch (e) {
      emit(UserProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Refresh profile
  Future<void> refresh() async {
    await fetchCurrentUserProfile();
  }

  /// Upload profile and/or background image(s), then refresh profile.
  Future<void> uploadProfileImages({File? profileImage, File? backgroundImage}) async {
    if ((profileImage == null || !profileImage.existsSync()) &&
        (backgroundImage == null || !backgroundImage.existsSync())) {
      return;
    }
    emit(UserProfileLoading());
    try {
      await _userProfileRepository.uploadProfileImages(
        profileImage: profileImage,
        backgroundImage: backgroundImage,
      );
      final profile = await _userProfileRepository.getCurrentUserProfile();
      emit(UserProfileImagesUploaded(profile));
    } catch (e) {
      emit(UserProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// PUT /profile/address — updates governorate + address, then emits new profile.
  Future<void> updateProfileAddress({
    required int governorateId,
    required String address,
  }) async {
    final current = state is UserProfileLoaded
        ? (state as UserProfileLoaded).profile
        : state is UserProfileImagesUploaded
            ? (state as UserProfileImagesUploaded).profile
            : null;
    if (current == null) return;
    try {
      final profile = await _userProfileRepository.updateProfileAddress(
        governorateId: governorateId,
        address: address,
      );
      emit(UserProfileLoaded(profile));
    } catch (e) {
      emit(UserProfileLoaded(current));
      rethrow;
    }
  }

  /// Reset to initial state
  void reset() {
    emit(UserProfileInitial());
  }
}

