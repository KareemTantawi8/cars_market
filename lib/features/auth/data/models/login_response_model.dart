import 'user_model.dart';

/// Login Response Model
class LoginResponseModel {
  final String message;
  final UserModel user;
  final List<dynamic> permissions;
  final String token;
  final String tokenType;
  final DateTime expiresAt;
  final List<String> abilities;

  LoginResponseModel({
    required this.message,
    required this.user,
    required this.permissions,
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.abilities,
  });

  /// Create from JSON
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      message: json['message'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      permissions: json['permissions'] as List<dynamic>? ?? [],
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
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

