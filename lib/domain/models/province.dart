import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// A province, from the Search Province endpoint of the step-by-step method.
class Province {
  const Province({required this.id, required this.name});

  /// Creates a province from one item of the `data` array.
  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(id: readInt(json, 'id'), name: readString(json, 'name'));
  }

  /// Province id, used as the path parameter of the Search City endpoint.
  final int id;

  /// Province name as returned by the API, for example `DKI JAKARTA`.
  final String name;

  /// Serializes this province back to its API shape.
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is Province && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Province($id, $name)';
}
