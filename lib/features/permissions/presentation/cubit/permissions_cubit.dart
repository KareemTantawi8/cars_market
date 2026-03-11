import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/permission_model.dart';
import '../../data/repositories/permissions_repository.dart';

abstract class PermissionsState {}

class PermissionsInitial extends PermissionsState {}

class PermissionsLoading extends PermissionsState {}

class PermissionsLoaded extends PermissionsState {
  final List<PermissionModel> permissions;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? search;

  PermissionsLoaded({
    required this.permissions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.search,
  });

  bool get hasMore => currentPage < lastPage;
}

class PermissionsError extends PermissionsState {
  final String message;
  PermissionsError(this.message);
}

class PermissionDetailLoaded extends PermissionsState {
  final PermissionModel permission;
  PermissionDetailLoaded(this.permission);
}

class PermissionDetailError extends PermissionsState {
  final String message;
  PermissionDetailError(this.message);
}

class PermissionActionSuccess extends PermissionsState {
  final String message;
  PermissionActionSuccess(this.message);
}

class PermissionActionError extends PermissionsState {
  final String message;
  PermissionActionError(this.message);
}

class PermissionsCubit extends Cubit<PermissionsState> {
  final PermissionsRepository _repository = PermissionsRepository();

  PermissionsCubit() : super(PermissionsInitial());

  /// Load list (page 1 or append). Uses search from previous Loaded state if not passed.
  Future<void> getPermissions({String? search, int page = 1, bool refresh = false}) async {
    if (page == 1 || refresh) {
      emit(PermissionsLoading());
    }
    try {
      final response = await _repository.getPermissions(
        search: search,
        perPage: 50,
        page: page,
      );
      final data = response['data'];
      final list = data is List ? data : (response['permissions'] is List ? response['permissions'] : <dynamic>[]);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => PermissionModel.fromJson(e))
          .toList();
      final meta = response['meta'] is Map<String, dynamic> ? response['meta'] as Map<String, dynamic> : null;
      final currentPage = meta != null ? (meta['current_page'] as num?)?.toInt() ?? 1 : 1;
      final lastPage = meta != null ? (meta['last_page'] as num?)?.toInt() ?? 1 : 1;
      final total = meta != null ? (meta['total'] as num?)?.toInt() ?? items.length : items.length;

      if (page == 1 || refresh) {
        emit(PermissionsLoaded(
          permissions: items,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
          search: search,
        ));
      } else {
        final currentState = state;
        if (currentState is PermissionsLoaded) {
          emit(PermissionsLoaded(
            permissions: [...currentState.permissions, ...items],
            currentPage: currentPage,
            lastPage: lastPage,
            total: total,
            search: currentState.search,
          ));
        }
      }
    } catch (e) {
      emit(PermissionsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> loadPermission(int id) async {
    try {
      final data = await _repository.getPermission(id);
      emit(PermissionDetailLoaded(PermissionModel.fromJson(data)));
    } catch (e) {
      emit(PermissionDetailError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> createPermission({required String name, required String slug, String? description}) async {
    try {
      await _repository.createPermission(name: name, slug: slug, description: description);
      emit(PermissionActionSuccess('تم إنشاء الصلاحية بنجاح'));
    } catch (e) {
      emit(PermissionActionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> updatePermission(int id, {String? name, String? slug, String? description}) async {
    try {
      await _repository.updatePermission(id, name: name, slug: slug, description: description);
      emit(PermissionActionSuccess('تم تحديث الصلاحية بنجاح'));
    } catch (e) {
      emit(PermissionActionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> deletePermission(int id) async {
    try {
      await _repository.deletePermission(id);
      emit(PermissionActionSuccess('تم حذف الصلاحية بنجاح'));
    } catch (e) {
      emit(PermissionActionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
