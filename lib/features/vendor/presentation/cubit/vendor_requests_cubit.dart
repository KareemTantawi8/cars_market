import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/vendor_repository.dart';

/// Vendor Requests State
abstract class VendorRequestsState {}

class VendorRequestsInitial extends VendorRequestsState {}

class VendorRequestsLoading extends VendorRequestsState {}

class VendorRequestsLoaded extends VendorRequestsState {
  final List<Map<String, dynamic>> requests;
  VendorRequestsLoaded(this.requests);
}

class VendorRequestsError extends VendorRequestsState {
  final String message;
  VendorRequestsError(this.message);
}

class VendorOnlineToggled extends VendorRequestsState {
  final bool isOnline;
  VendorOnlineToggled(this.isOnline);
}

/// Vendor Requests Cubit
class VendorRequestsCubit extends Cubit<VendorRequestsState> {
  final VendorRepository _repository;

  VendorRequestsCubit({VendorRepository? repository})
      : _repository = repository ?? VendorRepository(),
        super(VendorRequestsInitial());

  /// Get incoming requests
  Future<void> getIncomingRequests() async {
    emit(VendorRequestsLoading());
    try {
      final requests = await _repository.getIncomingRequests();
      emit(VendorRequestsLoaded(requests));
    } catch (e) {
      emit(VendorRequestsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Toggle online status
  Future<void> toggleOnline() async {
    try {
      final response = await _repository.toggleOnline();
      final isOnline = response['data']?['is_online'] ?? false;
      emit(VendorOnlineToggled(isOnline));
    } catch (e) {
      emit(VendorRequestsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

