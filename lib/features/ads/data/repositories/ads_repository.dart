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
        final bytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 1920,
          minHeight: 1080,
          quality: 80,
          format: CompressFormat.jpeg,
        );
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

    final response = await _api.post(
      ApiEndpoints.createAd,
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
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
        final bytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 1920,
          minHeight: 1080,
          quality: 80,
          format: CompressFormat.jpeg,
        );
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

    final response = await _api.put(
      ApiEndpoints.updateAd(id),
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
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
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 'Request failed';
    }
    return 'Request failed: ${response.statusCode}';
  }
}
