/// Vendor Register Request Model
class VendorRegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;
  final String companyName;
  final String governorate;

  VendorRegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.companyName,
    required this.governorate,
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
      'company_name': companyName,
      'governorate': governorate,
    };
  }
}

