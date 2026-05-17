import 'package:intl/intl.dart';

/// Formats a monetary amount for display (e.g. `1,250,000 ج.م`).
///
/// Uses Western digits and comma thousands separators so prices stay readable
/// in RTL Arabic layouts (including amounts with 10+ digits).
String formatPriceEgp(num? amount, {String currencySuffix = 'ج.م'}) {
  if (amount == null) return '0 $currencySuffix';
  final value = amount.round();
  final digits = NumberFormat.decimalPattern('en_US').format(value);
  return '$digits $currencySuffix';
}

/// Suggested font size for a formatted price string in tight UI (badges).
double priceDisplayFontSize(String formattedPrice, {double base = 15}) {
  final digitCount = formattedPrice.replaceAll(RegExp(r'[^0-9]'), '').length;
  if (digitCount > 12) return 11;
  if (digitCount > 9) return 12;
  if (digitCount > 7) return 13;
  return base;
}
