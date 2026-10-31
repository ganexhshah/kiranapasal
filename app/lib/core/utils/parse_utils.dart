// Safe number parsing utilities to gracefully handle both JSON numbers and
// PostgreSQL/Laravel string decimals (e.g. "120.00", "100.000") without TypeErrors.

double parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim()) ?? defaultValue;
  }
  return defaultValue;
}

int parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim()) ??
        double.tryParse(value.trim())?.toInt() ??
        defaultValue;
  }
  return defaultValue;
}
