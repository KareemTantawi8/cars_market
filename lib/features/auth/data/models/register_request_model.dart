/// Register Request Model
class RegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;
  final String? deviceToken;

  RegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    this.deviceName = 'Mobile',
    this.deviceToken,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': deviceName,
    };
    if (deviceToken != null && deviceToken!.isNotEmpty) {
      map['device_token'] = deviceToken;
    }
    return map;
  }
}

