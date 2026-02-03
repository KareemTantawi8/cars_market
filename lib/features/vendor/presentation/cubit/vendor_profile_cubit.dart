import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/vendor_profile_repository.dart';
import '../../data/models/vendor_profile_model.dart';

/// Vendor Profile State
abstract class VendorProfileState extends Equatable {
  const VendorProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VendorProfileInitial extends VendorProfileState {}

/// Loading state
class VendorProfileLoading extends VendorProfileState {}

/// Profile loaded successfully
class VendorProfileLoaded extends VendorProfileState {
  final VendorProfileModel profile;

  const VendorProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Error state
class VendorProfileError extends VendorProfileState {
  final String message;

  const VendorProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Vendor Profile Cubit
class VendorProfileCubit extends Cubit<VendorProfileState> {
  final VendorProfileRepository _vendorProfileRepository;

  VendorProfileCubit({VendorProfileRepository? vendorProfileRepository})
      : _vendorProfileRepository = vendorProfileRepository ?? VendorProfileRepository(),
        super(VendorProfileInitial());

  /// Fetch vendor profile by user ID
  Future<void> fetchVendorProfile(int userId) async {
    emit(VendorProfileLoading());

    try {
      final profile = await _vendorProfileRepository.getVendorProfile(userId);
      emit(VendorProfileLoaded(profile));
    } catch (e) {
      emit(VendorProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(VendorProfileInitial());
  }
}

