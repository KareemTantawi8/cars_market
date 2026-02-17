import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

/// API Client for making HTTP requests
class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;

  // Singleton pattern to ensure same instance is used everywhere
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor to log auth header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final authHeader = options.headers['Authorization'];
        if (authHeader != null) {
          _log('🔑 Authorization header present: ${authHeader.toString().substring(0, authHeader.toString().length > 30 ? 30 : authHeader.toString().length)}...');
        } else {
          _log('⚠️ No Authorization header in request');
        }
        handler.next(options);
      },
    ));

    // Add logging interceptor in debug mode
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));

    // Load token from storage if available
    _loadTokenFromStorage();
  }

  /// Load token from storage and set it (synchronous)
  void _loadTokenFromStorage() {
    try {
      final token = StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        _log('🔐 Auth token loaded from storage');
      } else {
        _log('ℹ️ No auth token found in storage');
      }
    } catch (e) {
      _log('⚠️ Error loading token from storage: $e');
    }
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _log('🔐 Auth token set: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
  }

  /// Remove authorization token
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
    _log('🔓 Auth token removed');
  }

  /// Refresh token from storage (useful after login)
  void refreshTokenFromStorage() {
    _loadTokenFromStorage();
  }

  /// Update base URL (useful when base URL changes)
  void updateBaseUrl() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _log('🔄 Base URL updated to: ${AppConstants.baseUrl}');
  }

  /// Log helper
  void _log(String message) {
    developer.log(message, name: 'ApiClient');
    // ignore: avoid_print
    print('📡 ApiClient: $message');
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _log('GET Request: ${AppConstants.baseUrl}$path');
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      _log('GET Response [$path]: Status ${response.statusCode}');
      _log('GET Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      _log('❌ GET Error [$path]: ${e.message}');
      _log('❌ Error Response: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _log('POST Request: ${AppConstants.baseUrl}$path');
    _log('POST Data: $data');
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _log('POST Response [$path]: Status ${response.statusCode}');
      _log('POST Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      _log('❌ POST Error [$path]: ${e.message}');
      _log('❌ Error Response: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _log('PUT Request: ${AppConstants.baseUrl}$path');
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _log('PUT Response [$path]: Status ${response.statusCode}');
      _log('PUT Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      _log('❌ PUT Error [$path]: ${e.message}');
      _log('❌ Error Response: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _log('DELETE Request: ${AppConstants.baseUrl}$path');
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      _log('DELETE Response [$path]: Status ${response.statusCode}');
      _log('DELETE Response Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      _log('❌ DELETE Error [$path]: ${e.message}');
      _log('❌ Error Response: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// Handle errors
  void _handleError(DioException error) {
    _log('🚨 Error Type: ${error.type}');
    _log('🚨 Error Status Code: ${error.response?.statusCode}');
    _log('🚨 Error Message: ${error.message}');
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _log('⏱️ Timeout error');
        break;
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401) {
          _log('🔒 Unauthorized - 401');
        } else if (error.response?.statusCode == 403) {
          _log('🚫 Forbidden - 403');
        } else if (error.response?.statusCode == 500) {
          _log('💥 Server error - 500');
        }
        break;
      case DioExceptionType.cancel:
        _log('🛑 Request cancelled');
        break;
      case DioExceptionType.unknown:
        _log('❓ Unknown error');
        break;
      default:
        break;
    }
  }
}

