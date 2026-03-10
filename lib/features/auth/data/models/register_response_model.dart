import 'user_model.dart';

/// Register Response Model
class RegisterResponseModel {
  final String message;
  final UserModel user;
  final List<dynamic> permissions;
  final String token;
  final String tokenType;
  final DateTime expiresAt;
  final List<String> abilities;

  RegisterResponseModel({
    required this.message,
    required this.user,
    required this.permissions,
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.abilities,
  });

  /// Create from JSON
  /// API may return { data: { user, token, expires_at } } or { user, token, ... }
  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson == null || userJson is! Map<String, dynamic>) {
      throw Exception('Register response missing user');
    }
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Register response missing token');
    }
    DateTime expiresAt = DateTime.now().add(const Duration(days: 365));
    if (json['expires_at'] != null) {
      try {
        expiresAt = DateTime.parse(json['expires_at'] as String);
      } catch (_) {}
    }
    return RegisterResponseModel(
      message: json['message'] as String? ?? 'تم التسجيل بنجاح',
      user: UserModel.fromJson(userJson),
      permissions: json['permissions'] as List<dynamic>? ?? [],
      token: token,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresAt: expiresAt,
      abilities: (json['abilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'permissions': permissions,
      'token': token,
      'token_type': tokenType,
      'expires_at': expiresAt.toIso8601String(),
      'abilities': abilities,
    };
  }
}

