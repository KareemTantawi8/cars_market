import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_profile_model.dart';

/// User Profile Repository - Handles user profile API calls
class UserProfileRepository {
  final ApiClient _apiClient;

  UserProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('👤 UserProfileRepository: $message');
    }
  }

  /// Get current user profile
  /// GET /api/v1/auth/me
  /// Requires Authorization header with Bearer token
  Future<UserProfileModel> getCurrentUserProfile() async {
    _log('📋 Fetching current user profile from: ${ApiEndpoints.currentUser}');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.currentUser,
      );

      _log('✅ User profile response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // API may return { "user": {...} } or { "data": { "user": {...} } }
          final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
          final userRaw = payload['user'];
          final userData = userRaw is Map<String, dynamic> ? userRaw : payload;
          final result = UserProfileModel.fromJson(userData);
          _log('✅ Parsed user profile: ${result.name} (ID: ${result.id}), vendor: ${result.vendor != null}');
          return result;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching user profile: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401) {
          throw Exception('غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى');
        }
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب بيانات المستخدم'
            : 'فشل في جلب بيانات المستخدم';
        throw Exception(errorMessage);
      } else {
        throw Exception('خطأ في الشبكة: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error fetching user profile: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// POST /api/v1/profile/images - Upload profile and/or background image (multipart). Profile max 2MB, background max 4MB. jpg/jpeg/png/webp.
  /// Returns { profile_image_url?, background_image_url? } from response data. 401/422.
  Future<Map<String, String>> uploadProfileImages({
    File? profileImage,
    File? backgroundImage,
  }) async {
    if ((profileImage == null || !profileImage.existsSync()) &&
        (backgroundImage == null || !backgroundImage.existsSync())) {
      throw Exception('يجب اختيار صورة واحدة على الأقل');
    }
    _log('📤 Uploading profile images');
    const profileMaxBytes = 2 * 1024 * 1024; // 2MB
    const backgroundMaxBytes = 4 * 1024 * 1024; // 4MB

      Future<MultipartFile> _fileToMultipart(File file, int maxBytes) async {
      final length = await file.length();
      final bytes = length > maxBytes
          ? await FlutterImageCompress.compressWithFile(
                file.absolute.path,
                minWidth: 1200,
                minHeight: 1200,
                quality: 85,
                format: CompressFormat.jpeg,
              )
          : await file.readAsBytes();
      if (bytes == null || bytes.isEmpty) throw Exception('فشل في ضغط الصورة');
      final name = file.path.split(RegExp(r'[/\\]')).last;
      final safeName = name.toLowerCase().endsWith('.jpg') ||
              name.toLowerCase().endsWith('.jpeg') ||
              name.toLowerCase().endsWith('.png') ||
              name.toLowerCase().endsWith('.webp')
          ? name
          : '${name.split('.').first}.jpg';
      return MultipartFile.fromBytes(bytes, filename: safeName);
    }

    final formData = FormData();
    if (profileImage != null && profileImage.existsSync()) {
      formData.files.add(MapEntry(
        'profile_image',
        await _fileToMultipart(profileImage, profileMaxBytes),
      ));
    }
    if (backgroundImage != null && backgroundImage.existsSync()) {
      formData.files.add(MapEntry(
        'background_image',
        await _fileToMultipart(backgroundImage, backgroundMaxBytes),
      ));
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.profileImages,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('فشل في رفع الصور: ${response.statusCode}');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) return {};
      final inner = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      final result = <String, String>{};
      if (inner['profile_image_url'] != null) result['profile_image_url'] = inner['profile_image_url'].toString();
      if (inner['background_image_url'] != null) result['background_image_url'] = inner['background_image_url'].toString();
      _log('✅ Profile images updated');
      return result;
    } on DioException catch (e) {
      _log('❌ Upload profile images: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          throw Exception('غير مصرح. يرجى تسجيل الدخول مرة أخرى');
        }
        if (e.response!.statusCode == 422) {
          final d = e.response!.data;
          if (d is Map<String, dynamic>) {
            final msg = d['message']?.toString() ?? 'التحقق من الملف فشل';
            final errors = d['errors'];
            if (errors is Map<String, dynamic>) {
              final parts = <String>[];
              for (final entry in errors.entries) {
                final v = entry.value;
                if (v is List && v.isNotEmpty) parts.add('${entry.key}: ${v.first}');
              }
              if (parts.isNotEmpty) throw Exception('$msg\n${parts.join('\n')}');
            }
            throw Exception(msg);
          }
        }
      }
      throw Exception(e.message ?? 'فشل في رفع الصور');
    }
  }
}

