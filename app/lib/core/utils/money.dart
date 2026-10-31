import 'package:intl/intl.dart';

final NumberFormat _groupedWhole = NumberFormat('#,##0');
final NumberFormat _groupedTwoDecimals = NumberFormat('#,##0.00');

/// Formats a money amount the way the whole app should display it:
/// no decimals for whole rupees, exactly two decimals otherwise, thousands
/// grouped. Use this instead of `toStringAsFixed(0)` / `.toInt()` so the same
/// bill never shows `Rs. 1234` on one screen and `Rs. 1,234.50` on another.
String formatAmount(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  final rounded = (value * 100).roundToDouble() / 100;
  final isWhole = (rounded - rounded.roundToDouble()).abs() < 0.005;
  return isWhole ? _groupedWhole.format(rounded) : _groupedTwoDecimals.format(rounded);
}

/// [formatAmount] prefixed with the currency symbol used across the app.
String formatMoney(double value, {String symbol = 'Rs.'}) =>
    '$symbol ${formatAmount(value)}';

/// Quantity formatting: whole quantities without decimals, fractional ones with
/// up to two decimals (0.5 kg stays 0.5, 2.0 becomes 2).
String formatQuantity(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  final rounded = (value * 100).roundToDouble() / 100;
  final isWhole = (rounded - rounded.roundToDouble()).abs() < 0.005;
  return isWhole ? rounded.toInt().toString() : rounded.toString();
}
