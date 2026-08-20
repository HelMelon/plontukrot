// JSON field helpers: FastAPI uses snake_case, legacy maps used camelCase.

String camelToSnake(String camel) {
  return camel.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

/// Reads [camel] or its snake_case equivalent from [data].
dynamic readField(Map<String, dynamic> data, String camel) {
  if (data.containsKey(camel) && data[camel] != null) {
    return data[camel];
  }
  final snake = camelToSnake(camel);
  if (data.containsKey(snake)) return data[snake];
  return data[camel];
}

String? readString(Map<String, dynamic> data, String camel) {
  final value = readField(data, camel);
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int? readInt(Map<String, dynamic> data, String camel) {
  final value = readField(data, camel);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? readDouble(Map<String, dynamic> data, String camel) {
  final value = readField(data, camel);
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool readBool(
  Map<String, dynamic> data,
  String camel, {
  bool fallback = false,
}) {
  final value = readField(data, camel);
  if (value is bool) return value;
  return fallback;
}

DateTime? readDate(Map<String, dynamic> data, String camel) {
  return readTimestamp(readField(data, camel));
}

/// Parses ISO-8601 strings, epoch millis/seconds, or [DateTime].
DateTime? readTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  if (value is int) {
    if (value > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is double) {
    return readTimestamp(value.round());
  }
  return null;
}

/// Enum from backend `int` index or legacy string `name`.
T readEnum<T extends Enum>(
  dynamic value,
  List<T> values,
  T fallback,
) {
  if (value is int && value >= 0 && value < values.length) {
    return values[value];
  }
  if (value is num) {
    final index = value.toInt();
    if (index >= 0 && index < values.length) return values[index];
  }
  if (value is String) {
    final normalized = value.trim();
    for (final item in values) {
      if (item.name == normalized) return item;
    }
  }
  return fallback;
}

String? isoOrNull(DateTime? value) =>
    value?.toUtc().toIso8601String();
