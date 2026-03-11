import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Permissions Repository - Handles permissions API (list, create, show, update, delete). Requires permissions.* abilities.
class PermissionsRepository {
  final ApiClient _apiClient = ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🔐 PermissionsRepository: $message');
    }
  }

  static String _messageFrom422(Map<String, dynamic> errorData) {
    final message = errorData['message']?.toString() ?? 'Validation failed';
    final errors = errorData['errors'];
    if (errors == null || errors is! Map<String, dynamic>) return message;
    final list = <String>[];
    for (final e in errors.entries) {
      final v = e.value;
      final text = v is List && v.isNotEmpty ? v.map((x) => x.toString()).join(', ') : v?.toString() ?? '';
      if (text.isNotEmpty) list.add('${e.key}: $text');
    }
    return list.isEmpty ? message : '$message\n${list.join('\n')}';
  }

  /// GET /api/v1/permissions - List paginated (search, per_page). 401/403.
  Future<Map<String, dynamic>> getPermissions({
    String? search,
    int perPage = 50,
    int page = 1,
  }) async {
    _log('📋 Getting permissions, page: $page');
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.permissions, queryParameters: query);
    if (response.statusCode != 200) throw Exception('Failed to load permissions: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid permissions response');
    return data;
  }

  /// GET /api/v1/permissions/:id - Show permission. 404.
  Future<Map<String, dynamic>> getPermission(int id) async {
    _log('📄 Getting permission: $id');
    final response = await _apiClient.get(ApiEndpoints.permissionById(id));
    if (response.statusCode != 200) throw Exception('Failed to load permission: ${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid permission response');
    return data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
  }

  /// POST /api/v1/permissions - Create (name, slug, description). 201/422.
  Future<Map<String, dynamic>> createPermission({
    required String name,
    required String slug,
    String? description,
  }) async {
    _log('➕ Creating permission: $slug');
    final body = <String, dynamic>{'name': name, 'slug': slug};
    if (description != null && description.isNotEmpty) body['description'] = description;
    try {
      final response = await _apiClient.post(ApiEndpoints.permissionCreate, data: body);
      if (response.statusCode != 201) throw Exception('Failed to create permission: ${response.statusCode}');
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('Invalid create permission response');
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 && e.response!.data is Map<String, dynamic>) {
        throw Exception(_messageFrom422(e.response!.data as Map<String, dynamic>));
      }
      rethrow;
    }
  }

  /// PUT /api/v1/permissions/:id - Update (name?, slug?, description?). 200/422.
  Future<Map<String, dynamic>> updatePermission(
    int id, {
    String? name,
    String? slug,
    String? description,
  }) async {
    _log('✏️ Updating permission: $id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (slug != null) body['slug'] = slug;
    if (description != null) body['description'] = description;
    try {
      final response = await _apiClient.put(ApiEndpoints.permissionUpdate(id), data: body);
      if (response.statusCode != 200) throw Exception('Failed to update permission: ${response.statusCode}');
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('Invalid update permission response');
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 && e.response!.data is Map<String, dynamic>) {
        throw Exception(_messageFrom422(e.response!.data as Map<String, dynamic>));
      }
      rethrow;
    }
  }

  /// DELETE /api/v1/permissions/:id - Delete. 200/422 if assigned to roles.
  Future<void> deletePermission(int id) async {
    _log('🗑️ Deleting permission: $id');
    try {
      final response = await _apiClient.delete(ApiEndpoints.permissionDelete(id));
      if (response.statusCode != 200) throw Exception('Failed to delete permission: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final msg = e.response!.data is Map<String, dynamic>
            ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Cannot delete permission assigned to roles'
            : 'Cannot delete permission assigned to roles';
        throw Exception(msg);
      }
      rethrow;
    }
  }
}
