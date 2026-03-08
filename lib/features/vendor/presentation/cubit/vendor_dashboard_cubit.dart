import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../data/models/vendor_profile_model.dart';

/// Vendor Dashboard State
abstract class VendorDashboardState extends Equatable {
  const VendorDashboardState();

  @override
  List<Object?> get props => [];
}

class VendorDashboardInitial extends VendorDashboardState {}

class VendorDashboardLoading extends VendorDashboardState {}

class VendorDashboardLoaded extends VendorDashboardState {
  final VendorProfileModel profile;

  const VendorDashboardLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class VendorDashboardError extends VendorDashboardState {
  final String message;

  const VendorDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Vendor Dashboard Cubit - Fetches auth/me and maps to vendor profile display
class VendorDashboardCubit extends Cubit<VendorDashboardState> {
  final UserProfileRepository _userProfileRepository;

  VendorDashboardCubit({UserProfileRepository? userProfileRepository})
      : _userProfileRepository = userProfileRepository ?? UserProfileRepository(),
        super(VendorDashboardInitial());

  /// Fetch vendor profile from auth/me
  Future<void> fetchVendorProfile() async {
    emit(VendorDashboardLoading());

    try {
      final userProfile = await _userProfileRepository.getCurrentUserProfile();

      if (userProfile.vendor == null) {
        emit(const VendorDashboardError('هذا الحساب ليس حساب تاجر'));
        return;
      }

      final vendorProfile = _mapToVendorProfileModel(userProfile);
      emit(VendorDashboardLoaded(vendorProfile));
    } catch (e) {
      emit(VendorDashboardError(
          e.toString().replaceAll('Exception: ', '')));
    }
  }

  VendorProfileModel _mapToVendorProfileModel(UserProfileModel user) {
    final v = user.vendor!;

    // Build full address: address, city, governorate
    final addressParts = [
      v.address,
      v.city,
      v.governorate?.name,
    ].whereType<String>().where((s) => s.isNotEmpty);
    final fullAddress = addressParts.isNotEmpty ? addressParts.join('، ') : null;

    // Parse response time for minutes (e.g. "7 minutes 24 seconds" -> 7)
    int? responseTimeMinutes;
    if (v.responseTimeHuman != null) {
      final match = RegExp(r'(\d+)\s*(?:دقيقة|minute|دقائق|minutes)',
              caseSensitive: false)
          .firstMatch(v.responseTimeHuman!);
      if (match != null) {
        responseTimeMinutes = int.tryParse(match.group(1) ?? '');
      }
    }

    return VendorProfileModel(
      id: v.id,
      name: v.companyName.isNotEmpty ? v.companyName : user.name,
      description: v.description,
      isVerified: v.isVerified,
      isOpen: v.isOnline,
      openUntil: v.isOnline ? 'متصل' : null,
      responseTimeMinutes: responseTimeMinutes,
      responseTimeHuman: v.responseTimeHuman,
      rating: v.averageRating,
      ratingCount: v.ratingsCount,
      supportedBrands: v.brands.map((b) => b.name).toList(),
      availableServices: const [], // auth/me does not include services
      phone: v.phone ?? user.phone,
      whatsapp: v.phone ?? user.phone,
      address: fullAddress ?? v.address,
      governorate: v.governorate?.name,
      latitude: null,
      longitude: null,
      googleMapsUrl: v.googleMapsUrl,
      imageUrl: user.imageUrl,
      backgroundImageUrl: user.backgroundImageUrl,
    );
  }

  Future<void> refresh() async {
    await fetchVendorProfile();
  }
}
