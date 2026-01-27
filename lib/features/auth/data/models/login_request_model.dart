/// Login Request Model
class LoginRequestModel {
  final String phone;
  final String password;
  final String deviceName;
  final String tokenType;

  LoginRequestModel({
    required this.phone,
    required this.password,
    this.deviceName = 'Mobile',
    this.tokenType = 'mobile',
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
      'device_name': deviceName,
      'token_type': tokenType,
    };
  }
}

