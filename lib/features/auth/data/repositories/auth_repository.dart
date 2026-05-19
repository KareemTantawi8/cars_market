import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/register_request_model.dart';
import '../models/vendor_register_request_model.dart';
import '../models/register_response_model.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// Auth Repository - Handles authentication API calls
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Build a readable message from API 422 validation errors
  /// API: { "success": false, "message": "Validation failed", "errors": { "phone": ["The phone has already been taken."], ... } }
  static String _messageFrom422(Map<String, dynamic> errorData) {
    final message = errorData['message'] as String? ?? 'Validation failed';
    final errors = errorData['errors'];
    if (errors == null || errors is! Map<String, dynamic>) return message;
    final list = <String>[];
    for (final entry in errors.entries) {
      final field = entry.key;
      final value = entry.value;
      final text = value is List && value.isNotEmpty
          ? value.map((e) => e.toString()).join(', ')
          : value?.toString() ?? '';
      if (text.isNotEmpty) list.add('$field: $text');
    }
    if (list.isEmpty) return message;
    return '$message\n${list.join('\n')}';
  }

  /// Register as user (customer)
  Future<RegisterResponseModel> registerAsUser(
    RegisterRequestModel request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final payload = data is Map<String, dynamic> && data['data'] != null
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return RegisterResponseModel.fromJson(payload);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (statusCode == 422 && errorData is Map<String, dynamic>) {
          throw Exception(_messageFrom422(errorData));
        }
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Registration failed'
            : 'Registration failed';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Register as vendor
  Future<RegisterResponseModel> registerAsVendor(
    VendorRegisterRequestModel request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerVendor,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final payload = data is Map<String, dynamic> && data['data'] != null
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return RegisterResponseModel.fromJson(payload);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (statusCode == 422 && errorData is Map<String, dynamic>) {
          throw Exception(_messageFrom422(errorData));
        }
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Registration failed'
            : 'Registration failed';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Login
  Future<LoginResponseModel> login(
    LoginRequestModel request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final payload = data is Map<String, dynamic> && data['data'] != null
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return LoginResponseModel.fromJson(payload);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        if (statusCode == 422 && errorData is Map<String, dynamic>) {
          throw Exception(_messageFrom422(errorData));
        }
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'Login failed'
            : 'Login failed';
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get current user profile
  /// GET /api/v1/auth/me - Returns 200 with { user, permissions?, token_abilities?, is_dashboard?, is_mobile? }
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentUser);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) throw Exception('Invalid auth/me response');
        // API may return top-level { user, ... } or wrapped { data: { user, ... } }
        final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
        final userRaw = payload['user'];
        if (userRaw is Map<String, dynamic>) return UserModel.fromJson(userRaw);
        return UserModel.fromJson(payload);
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to get user: ${e.message}');
    }
  }

  /// Logout
  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      // Even if logout fails, we should clear local token
      throw Exception('Logout failed: ${e.message}');
    }
  }

  /// Permanently delete the authenticated user's account.
  /// DELETE /api/v1/profile
  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deleteProfile);
      final code = response.statusCode;
      if (code == 200 || code == 204 || code == 202) {
        return;
      }
      throw Exception('فشل حذف الحساب');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
      }
      final errorData = e.response?.data;
      final errorMessage = errorData is Map<String, dynamic>
          ? errorData['message'] ?? errorData['error'] ?? 'فشل حذف الحساب'
          : 'فشل حذف الحساب';
      throw Exception(errorMessage);
    }
  }

  /// Refresh token
  /// POST /api/v1/auth/refresh
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.refreshToken);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to refresh token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to refresh token: ${e.message}');
    }
  }

  /// Forgot password - Send OTP
  /// POST /api/v1/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to send OTP: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to send OTP'
            : 'Failed to send OTP';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Verify OTP
  /// POST /api/v1/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Invalid OTP'
            : 'Invalid OTP';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Reset password
  /// POST /api/v1/auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'phone': phone,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final inner = data['data'];
          return inner is Map<String, dynamic> ? inner : data;
        }
        return <String, dynamic>{};
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? 'Failed to reset password'
            : 'Failed to reset password';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get active tokens
  /// GET /api/v1/auth/tokens
  Future<List<Map<String, dynamic>>> getActiveTokens() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.authTokens);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['tokens'] != null) {
          return List<Map<String, dynamic>>.from(data['tokens'] as List);
        }
        return [];
      } else {
        throw Exception('Failed to get tokens: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to get tokens: ${e.message}');
    }
  }

  /// Revoke token
  /// DELETE /api/v1/auth/tokens/{id}
  Future<void> revokeToken(int tokenId) async {
    try {
      await _apiClient.delete(ApiEndpoints.revokeToken(tokenId));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Token already revoked');
      }
      throw Exception('Failed to revoke token: ${e.message}');
    }
  }

  /// Logout from all devices
  /// POST /api/v1/auth/logout-all
  Future<void> logoutAll() async {
    try {
      await _apiClient.post(ApiEndpoints.logoutAll);
    } on DioException catch (e) {
      throw Exception('Failed to logout from all devices: ${e.message}');
    }
  }
}

