import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ad_model.dart';

/// Repository for Ads API: list, get by id, create, update, delete, my-ads, admin approve/reject
class AdsRepository {
  final ApiClient _api = ApiClient();

  /// GET /ads - List published ads with optional filters
  Future<PaginatedAdsResponse> getAds({
    int? brandId,
    int? modelId,
    int? yearId,
    String? condition,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (brandId != null) query['brand_id'] = brandId;
    if (modelId != null) query['model_id'] = modelId;
    if (yearId != null) query['year_id'] = yearId;
    if (condition != null && condition.isNotEmpty) query['condition'] = condition;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _api.get(ApiEndpoints.ads, queryParameters: query);
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: expected map');
    // API may return { data: [...], current_page, ... } - data is the list; use full map for fromJson
    final payload = (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : data;
    return PaginatedAdsResponse.fromJson(payload);
  }

  /// GET /ads/:id - View single ad
  Future<AdModel> getAdById(int id) async {
    final response = await _api.get(ApiEndpoints.adById(id));
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Ad not found');
    final raw = data['data'];
    final adData = raw is Map<String, dynamic> ? raw : (raw is List && raw.isNotEmpty && raw.first is Map ? raw.first as Map<String, dynamic> : data);
    return AdModel.fromJson(adData);
  }

  /// POST /ads - Create ad (multipart/form-data)
  Future<AdModel> createAd({
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
    final formData = FormData.fromMap({
      'title': title,
      'brand_id': brandId,
      'condition': condition,
      'is_negotiable': isNegotiable ? '1' : '0',
      'is_phone_visible': isPhoneVisible ? '1' : '0',
      if (description != null && description.isNotEmpty) 'description': description,
      if (modelId != null) 'model_id': modelId,
      if (yearId != null) 'year_id': yearId,
      if (price != null) 'price': price,
      if (expiresAt != null && expiresAt.isNotEmpty) 'expires_at': expiresAt,
    });

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (int i = 0; i < imageFiles.length && i < 5; i++) {
        final file = imageFiles[i];
        final bytes = await _compressImageForUpload(file, maxBytes: 280 * 1024); // ~280KB per image so 5 fit under ~1.5MB total
        final filename = file.path.split(RegExp(r'[/\\]')).last;
        final name = filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')
            ? filename
            : '${filename.split('.').first}.jpg';
        formData.files.add(MapEntry(
          'images[]',
          bytes != null && bytes.isNotEmpty
              ? MultipartFile.fromBytes(bytes, filename: name)
              : await MultipartFile.fromFile(file.path, filename: filename),
        ));
      }
    }

    Response response;
    try {
      response = await _api.post(
        ApiEndpoints.createAd,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('حجم الصور كبير جداً. جرب تقليل عدد الصور أو استخدام صور أصغر.');
      }
      throw Exception(_messageFromDioException(e));
    }
    if (response.statusCode != 201) {
      throw Exception(_messageFromResponse(response));
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: no data');
    final raw = data['data'];
    final adData = raw is Map<String, dynamic> ? raw : (raw is List && raw.isNotEmpty && raw.first is Map ? raw.first as Map<String, dynamic> : data);
    return AdModel.fromJson(adData);
  }

  /// PUT /ads/:id - Update ad (multipart/form-data)
  Future<AdModel> updateAd(
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
    final map = <String, dynamic>{};
    if (title != null && title.isNotEmpty) map['title'] = title;
    if (description != null) map['description'] = description;
    if (brandId != null) map['brand_id'] = brandId;
    if (modelId != null) map['model_id'] = modelId;
    if (yearId != null) map['year_id'] = yearId;
    if (condition != null && condition.isNotEmpty) map['condition'] = condition;
    if (price != null) map['price'] = price;
    if (isNegotiable != null) map['is_negotiable'] = isNegotiable ? '1' : '0';
    if (isPhoneVisible != null) map['is_phone_visible'] = isPhoneVisible ? '1' : '0';
    if (isActive != null) map['is_active'] = isActive ? '1' : '0';
    if (expiresAt != null && expiresAt.isNotEmpty) map['expires_at'] = expiresAt;

    final formData = FormData.fromMap(map);

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (int i = 0; i < imageFiles.length && i < 5; i++) {
        final file = imageFiles[i];
        final bytes = await _compressImageForUpload(file, maxBytes: 280 * 1024);
        final filename = file.path.split(RegExp(r'[/\\]')).last;
        final name = filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')
            ? filename
            : '${filename.split('.').first}.jpg';
        formData.files.add(MapEntry(
          'images[]',
          bytes != null && bytes.isNotEmpty
              ? MultipartFile.fromBytes(bytes, filename: name)
              : await MultipartFile.fromFile(file.path, filename: filename),
        ));
      }
    }

    Response response;
    try {
      response = await _api.put(
        ApiEndpoints.updateAd(id),
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('حجم الصور كبير جداً. جرب تقليل عدد الصور أو استخدام صور أصغر.');
      }
      throw Exception(_messageFromDioException(e));
    }
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: no data');
    final raw = data['data'];
    final adData = raw is Map<String, dynamic> ? raw : (raw is List && raw.isNotEmpty && raw.first is Map ? raw.first as Map<String, dynamic> : data);
    return AdModel.fromJson(adData);
  }

  /// DELETE /ads/:id - Delete ad
  Future<void> deleteAd(int id) async {
    final response = await _api.delete(ApiEndpoints.deleteAd(id));
    _ensureSuccess(response);
  }

  /// GET /users/:userId/ads — public ads for that user account.
  Future<List<AdModel>> getAdsByUserId(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    if (userId <= 0) return [];
    final response = await _api.get(
      ApiEndpoints.userPublicAds(userId),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response: expected map');
    }
    final raw = data['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((map) {
      if ((map['user_id'] == null || map['user_id'] == 0) &&
          map['user'] is Map) {
        final uid = (map['user'] as Map)['id'];
        if (uid != null) {
          map['user_id'] = uid is int ? uid : (uid is num ? uid.toInt() : int.tryParse(uid.toString()) ?? 0);
        }
      }
      return AdModel.fromJson(map);
    }).toList();
  }

  /// GET /my-ads - List current user's ads (paginated)
  Future<PaginatedAdsResponse> getMyAds({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.myAds,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: expected map');
    final payload = (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : data;
    return PaginatedAdsResponse.fromJson(payload);
  }

  /// POST /admin/ads/:id/approve - Approve a pending ad (admin)
  Future<AdModel> approveAd(int id) async {
    final response = await _api.post(ApiEndpoints.adminApproveAd(id));
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: no data');
    final raw = data['data'];
    final adData = raw is Map<String, dynamic> ? raw : (raw is List && raw.isNotEmpty && raw.first is Map ? raw.first as Map<String, dynamic> : data);
    return AdModel.fromJson(adData);
  }

  /// POST /admin/ads/:id/reject - Reject a pending ad with reason (admin)
  Future<AdModel> rejectAd(int id, {String? rejectionReason}) async {
    final body = rejectionReason != null && rejectionReason.isNotEmpty
        ? <String, dynamic>{'rejection_reason': rejectionReason}
        : null;
    final response = await _api.post(
      ApiEndpoints.adminRejectAd(id),
      data: body,
    );
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) throw Exception('Invalid response: no data');
    final raw = data['data'];
    final adData = raw is Map<String, dynamic> ? raw : (raw is List && raw.isNotEmpty && raw.first is Map ? raw.first as Map<String, dynamic> : data);
    return AdModel.fromJson(adData);
  }

  void _ensureSuccess(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) return;
    throw Exception(_messageFromResponse(response));
  }

  String _messageFromResponse(Response response) {
    return _messageFromResponseData(response.data) ??
        'Request failed: ${response.statusCode}';
  }

  String _messageFromDioException(DioException e) {
    final fromBody = _messageFromResponseData(e.response?.data);
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;
    return e.message ?? 'تعذّر إتمام الطلب';
  }

  /// Extracts API `message`, validation `errors`, or `required_permissions`.
  String? _messageFromResponseData(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final errors = data['errors'];
    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) {
          parts.add(v.first.toString());
        } else if (v != null) {
          parts.add(v.toString());
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }

    final msg = data['message']?.toString().trim();
    if (msg == null || msg.isEmpty) return null;

    final perms = data['required_permissions'];
    if (perms is List && perms.isNotEmpty) {
      final list = perms.map((p) => p.toString()).join(', ');
      return '$msg\n($list)';
    }
    return msg;
  }

  /// Compress image to stay under [maxBytes] to avoid 413 from nginx. Targets ~280KB per image so 5 images fit under 1.5MB.
  Future<List<int>?> _compressImageForUpload(File file, {int maxBytes = 280 * 1024}) async {
    List<int>? lastResult;
    const widths = [1280, 1024, 800];
    const qualities = [65, 55, 45, 35];
    for (final w in widths) {
      for (final q in qualities) {
        final bytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: w,
          minHeight: (w * 9 / 16).round(),
          quality: q,
          format: CompressFormat.jpeg,
        );
        if (bytes != null && bytes.isNotEmpty) {
          lastResult = bytes;
          if (bytes.length <= maxBytes) return bytes;
        }
      }
    }
    return lastResult;
  }
}
