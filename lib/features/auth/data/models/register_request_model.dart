/// Register Request Model
class RegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;

  RegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    this.deviceName = 'Mobile',
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': deviceName,
    };
  }
}

