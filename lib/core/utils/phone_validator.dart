import 'package:flutter/services.dart';

/// Egyptian mobile phone validation (01X XXXX XXXX).
class PhoneValidator {
  PhoneValidator._();

  /// Local format: 11 digits starting with 01 (010, 011, 012, 015).
  static final RegExp _egyptMobileLocal =
      RegExp(r'^01[0125]\d{8}$');

  static const int egyptLocalLength = 11;

  /// Digits-only keyboard helpers for login/register fields.
  static List<TextInputFormatter> get egyptPhoneInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(egyptLocalLength),
      ];

  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Normalizes to local 11-digit form (01XXXXXXXXX).
  static String normalizeToLocal(String input) {
    var d = digitsOnly(input);
    if (d.startsWith('20') && d.length >= 12) {
      d = '0${d.substring(2)}';
    }
    if (d.length == 10 && d.startsWith('1')) {
      d = '0$d';
    }
    return d;
  }

  static bool isValidEgyptMobile(String input) {
    final local = normalizeToLocal(input);
    return _egyptMobileLocal.hasMatch(local);
  }

  /// Returns an Arabic error message, or null if valid.
  static String? validateEgyptMobile(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'الرجاء إدخال رقم الموبايل';
    }
    if (!isValidEgyptMobile(input)) {
      return 'رقم الموبايل غير صحيح (يجب أن يكون رقم مصري يبدأ بـ 01)';
    }
    return null;
  }
}
