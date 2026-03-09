Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

List<Map<String, dynamic>> asListOfMaps(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> asStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String parseString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final parsed = value.toString().trim();
  return parsed.isEmpty ? fallback : parsed;
}

String? parseNullableString(Object? value) {
  if (value == null) {
    return null;
  }

  final parsed = value.toString().trim();
  return parsed.isEmpty ? null : parsed;
}

DateTime? parseDate(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

int parseInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  return fallback;
}

double? parseDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim());
  }

  return null;
}

bool parseBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }

  return fallback;
}