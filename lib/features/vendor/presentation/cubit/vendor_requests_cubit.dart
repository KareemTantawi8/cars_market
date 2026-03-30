import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/vendor_repository.dart';

/// Normalizes Reverb `search-request.feed-card` payloads to match list API shape.
Map<String, dynamic> normalizeVendorFeedCard(Map<String, dynamic> raw) {
  dynamic brand = raw['brand'];
  dynamic model = raw['model'];
  final brandMap = brand is Map<String, dynamic>
      ? Map<String, dynamic>.from(brand)
      : <String, dynamic>{'name': brand?.toString() ?? ''};
  final modelMap = model is Map<String, dynamic>
      ? Map<String, dynamic>.from(model)
      : <String, dynamic>{'name': model?.toString() ?? ''};
  Map<String, dynamic> customer = {};
  final c = raw['customer'];
  if (c is Map<String, dynamic>) {
    customer = Map<String, dynamic>.from(c);
  } else {
    customer = {'name': 'عميل', 'id': 0};
  }
  return {
    ...raw,
    'brand': brandMap,
    'model': modelMap,
    'customer': customer,
  };
}

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

  /// Live feed: insert card from Reverb `search-request.feed-card`.
  void applyFeedCard(Map<String, dynamic> raw) {
    final normalized = normalizeVendorFeedCard(Map<String, dynamic>.from(raw));
    final id = normalized['id']?.toString();
    if (id == null) return;

    if (state is VendorRequestsLoaded) {
      final list = List<Map<String, dynamic>>.from((state as VendorRequestsLoaded).requests);
      if (list.any((r) => r['id']?.toString() == id)) return;
      list.insert(0, normalized);
      emit(VendorRequestsLoaded(list));
    } else {
      getIncomingRequests();
    }
  }

  /// Remove a row when `search-request.expired` / `search-request.rejected` fires.
  void removeBySearchRequestId(int searchRequestId) {
    if (state is! VendorRequestsLoaded) return;
    final list = (state as VendorRequestsLoaded)
        .requests
        .where((r) => r['id']?.toString() != searchRequestId.toString())
        .toList();
    emit(VendorRequestsLoaded(list));
  }
}

