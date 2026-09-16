import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// A city, from the Search City endpoint of the step-by-step method.
class City {
  const City({required this.id, required this.name, required this.zipCode});

  /// Creates a city from one item of the `data` array.
  ///
  /// `zip_code` is sometimes missing or `0`, so it is optional here.
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: readInt(json, 'id'),
      name: readString(json, 'name'),
      zipCode: readStringOr(json, 'zip_code'),
    );
  }

  /// City id, used as the path parameter of the Search District endpoint.
  final int id;

  /// City name as returned by the API.
  final String name;

  /// Postal code, which may be empty or `0`.
  final String zipCode;

  /// Serializes this city back to its API shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'zip_code': zipCode,
  };

  @override
  bool operator ==(Object other) =>
      other is City &&
      other.id == id &&
      other.name == name &&
      other.zipCode == zipCode;

  @override
  int get hashCode => Object.hash(id, name, zipCode);

  @override
  String toString() => 'City($id, $name)';
}
