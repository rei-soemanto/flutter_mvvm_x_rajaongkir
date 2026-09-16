import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// A shipping destination country, from the Search International Destination
/// endpoint of the direct search method.
///
/// The API returns `country_id` as a string, and that value is what the
/// International Calculate Cost endpoint expects as `destination`.
class Country {
  const Country({required this.id, required this.name});

  /// Creates a country from one item of the `data` array.
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: readString(json, 'country_id'),
      name: readString(json, 'country_name'),
    );
  }

  /// Country id, sent as `destination` when calculating an international cost.
  final String id;

  /// Country name, for example `Malaysia`.
  final String name;

  /// Serializes this country back to its API shape.
  Map<String, dynamic> toJson() => {'country_id': id, 'country_name': name};

  @override
  bool operator ==(Object other) =>
      other is Country && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Country($id, $name)';
}
