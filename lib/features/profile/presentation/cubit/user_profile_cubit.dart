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

  /// Reset to initial state
  void reset() {
    emit(UserProfileInitial());
  }
}

