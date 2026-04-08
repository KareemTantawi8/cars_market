/// Vendor Register Request Model
/// POST /api/v1/auth/register-vendor
/// Body: name, phone, password, password_confirmation, device_name,
///       company_name, governorate_id, address (optional), category_ids (optional).
class VendorRegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;
  final String companyName;
  final int governorateId;
  final String? address;

  /// Category ids (API: `category_ids`). UI may load options from `/categories/brands`;
  /// ids are sent as returned by the API.
  final List<int>? categoryIds;

  VendorRegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.companyName,
    required this.governorateId,
    this.deviceName = 'Flutter App',
    this.address,
    this.categoryIds,
  });

  static List<int> _dedupeIds(List<int> ids) {
    final seen = <int>{};
    return [for (final id in ids) if (seen.add(id)) id];
  }

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
    if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      map['category_ids'] = _dedupeIds(categoryIds!);
    }
    return map;
  }
}
