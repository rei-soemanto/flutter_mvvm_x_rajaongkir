/// Helpers for reading values out of a decoded JSON map.
///
/// The RajaOngkir payloads are not perfectly consistent: `cost` arrives as a
/// number, `country_id` as a string, `description` is sometimes numeric text
/// and `zip_code` is occasionally missing. These helpers accept those shapes
/// and throw a [FormatException] naming the field when a required value really
/// is unusable.
library;

/// Reads a required integer, accepting numeric strings.
int readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v when int.tryParse(v) != null => int.parse(v),
    _ => throw FormatException('Expected an integer at "$key", got: $value'),
  };
}

/// Reads an optional integer, returning null when absent or unusable.
int? readIntOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// Reads a required string, accepting numbers.
String readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    final String v => v,
    final num v => v.toString(),
    _ => throw FormatException('Expected a string at "$key", got: $value'),
  };
}

/// Reads a string that may be missing or null, falling back to [fallback].
String readStringOr(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  return switch (value) {
    final String v => v,
    final num v => v.toString(),
    _ => fallback,
  };
}

/// Reads an optional string, returning null when absent.
String? readStringOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return switch (value) {
    final String v => v,
    final num v => v.toString(),
    _ => null,
  };
}

/// Casts a decoded JSON value to a map, throwing a [FormatException] if it is
/// not one.
Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Expected a JSON object, got: $value');
}

/// Casts a decoded JSON value to a list of maps.
List<Map<String, dynamic>> asJsonList(Object? value) {
  if (value is List) {
    return value.map(asJsonMap).toList();
  }
  throw FormatException('Expected a JSON array, got: $value');
}
