import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// A district, from the Search District endpoint of the step-by-step method.
///
/// The District Calculate Cost endpoint expects district ids for both `origin`
/// and `destination`.
class District {
  const District({required this.id, required this.name, required this.zipCode});

  /// Creates a district from one item of the `data` array.
  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: readInt(json, 'id'),
      name: readString(json, 'name'),
      zipCode: readStringOr(json, 'zip_code'),
    );
  }

  /// District id, sent to the District Calculate Cost endpoint.
  final int id;

  /// District name as returned by the API.
  final String name;

  /// Postal code, which may be empty or `0`.
  final String zipCode;

  /// Serializes this district back to its API shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'zip_code': zipCode,
  };

  @override
  bool operator ==(Object other) =>
      other is District &&
      other.id == id &&
      other.name == name &&
      other.zipCode == zipCode;

  @override
  int get hashCode => Object.hash(id, name, zipCode);

  @override
  String toString() => 'District($id, $name)';
}
