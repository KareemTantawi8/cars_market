/// Vendor Register Request Model
/// API: name, phone, password, password_confirmation, device_name,
///      company_name, governorate_id, address (optional), category_ids (optional),
///      shop_phone (optional)
class VendorRegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;
  final String companyName;
  final int governorateId;
  final String? address;
  final List<int>? categoryIds;
  /// رقم المحل / رقم التواصل المختلف عن رقم التسجيل
  final String? shopPhone;
  final String? deviceToken;

  VendorRegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.companyName,
    required this.governorateId,
    this.deviceName = 'Mobile',
    this.address,
    this.categoryIds,
    this.shopPhone,
    this.deviceToken,
  });

  /// Convert to JSON for API request (snake_case)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': deviceName,
      'company_name': companyName,
      'governorate_id': governorateId,
    };
    if (address != null && address!.trim().isNotEmpty) map['address'] = address!.trim();
    if (categoryIds != null && categoryIds!.isNotEmpty) map['category_ids'] = categoryIds;
    if (shopPhone != null && shopPhone!.trim().isNotEmpty) map['shop_phone'] = shopPhone!.trim();
    if (deviceToken != null && deviceToken!.isNotEmpty) map['device_token'] = deviceToken;
    return map;
  }
}

