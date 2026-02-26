import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ad_model.dart';

/// Repository for Ads API: list, get by id, create, delete, my-ads
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
    final data = response.data as Map<String, dynamic>?;
    final dataPayload = data?['data'] as Map<String, dynamic>?;
    if (dataPayload == null) throw Exception('Invalid response: no data');
    return PaginatedAdsResponse.fromJson(dataPayload);
  }

  /// GET /ads/:id - View single ad
  Future<AdModel> getAdById(int id) async {
    final response = await _api.get(ApiEndpoints.adById(id));
    _ensureSuccess(response);
    final data = response.data as Map<String, dynamic>?;
    final adData = data?['data'] as Map<String, dynamic>?;
    if (adData == null) throw Exception('Ad not found');
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
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            imageFiles[i].path,
            filename: imageFiles[i].path.split(RegExp(r'[/\\]')).last,
          ),
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
    final data = response.data as Map<String, dynamic>?;
    final adData = data?['data'] as Map<String, dynamic>?;
    if (adData == null) throw Exception('Invalid response: no data');
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
    final data = response.data as Map<String, dynamic>?;
    final dataPayload = data?['data'] as Map<String, dynamic>?;
    if (dataPayload == null) throw Exception('Invalid response: no data');
    return PaginatedAdsResponse.fromJson(dataPayload);
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
