/// Login Request Model
class LoginRequestModel {
  final String phone;
  final String password;
  final String deviceName;
  final String tokenType;
  final String? deviceToken;

  LoginRequestModel({
    required this.phone,
    required this.password,
    this.deviceName = 'Mobile',
    this.tokenType = 'mobile',
    this.deviceToken,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phone': phone,
      'password': password,
      'device_name': deviceName,
      'token_type': tokenType,
    };
    if (deviceToken != null && deviceToken!.isNotEmpty) {
      map['device_token'] = deviceToken;
    }
    return map;
  }
}

