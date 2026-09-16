import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// A place found by the Search Domestic Destination endpoint (direct search
/// method).
///
/// Its [id] identifies a sub-district and is what the International Calculate
/// Cost endpoint expects as `origin`.
class DomesticDestination {
  const DomesticDestination({
    required this.id,
    required this.label,
    required this.provinceName,
    required this.cityName,
    required this.districtName,
    required this.subdistrictName,
    required this.zipCode,
  });

  /// Creates a destination from one item of the `data` array.
  factory DomesticDestination.fromJson(Map<String, dynamic> json) {
    return DomesticDestination(
      id: readInt(json, 'id'),
      label: readStringOr(json, 'label'),
      provinceName: readStringOr(json, 'province_name'),
      cityName: readStringOr(json, 'city_name'),
      districtName: readStringOr(json, 'district_name'),
      subdistrictName: readStringOr(json, 'subdistrict_name'),
      zipCode: readStringOr(json, 'zip_code'),
    );
  }

  /// Destination id, sent as `origin` when calculating an international cost.
  final int id;

  /// Full address line, for example
  /// `SINDUHARJO, NGAGLIK, SLEMAN, DI YOGYAKARTA, 55581`.
  final String label;

  /// Province name.
  final String provinceName;

  /// City name.
  final String cityName;

  /// District name.
  final String districtName;

  /// Sub-district name.
  final String subdistrictName;

  /// Postal code.
  final String zipCode;

  /// A short label for places where the full [label] is too long.
  String get shortLabel {
    final parts = [
      subdistrictName,
      districtName,
      cityName,
    ].where((part) => part.isNotEmpty);
    return parts.isEmpty ? label : parts.join(', ');
  }

  /// Serializes this destination back to its API shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'province_name': provinceName,
    'city_name': cityName,
    'district_name': districtName,
    'subdistrict_name': subdistrictName,
    'zip_code': zipCode,
  };

  @override
  bool operator ==(Object other) =>
      other is DomesticDestination && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'DomesticDestination($id, $label)';
}
