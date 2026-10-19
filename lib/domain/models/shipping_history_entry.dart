import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// Which page produced a history entry.
enum ShipmentType {
  /// A District Calculate Cost result from the domestic page.
  domestic,

  /// An International Calculate Cost result from the international page.
  international,
}

/// One saved calculation.
///
/// Entries are written by the domestic and international view models after a
/// successful calculation and stored on the device, so the history page can
/// show them again after a restart.
sealed class ShippingHistoryEntry {
  const ShippingHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.originLabel,
    required this.destinationLabel,
    required this.weightGrams,
    required this.courierCodes,
  });

  /// Restores an entry, choosing the subtype from the stored `type` field.
  static ShippingHistoryEntry fromJson(Map<String, dynamic> json) {
    final type = readStringOr(json, 'type');
    return switch (type) {
      'domestic' => DomesticHistoryEntry.fromJson(json),
      'international' => InternationalHistoryEntry.fromJson(json),
      _ => throw FormatException('Unknown history entry type: $type'),
    };
  }

  /// Unique id, also used as the argument of the history detail route.
  final String id;

  /// When the calculation was made.
  final DateTime createdAt;

  /// Where the parcel is sent from, already formatted for display.
  final String originLabel;

  /// Where the parcel is sent to, already formatted for display.
  final String destinationLabel;

  /// Parcel weight in grams.
  final int weightGrams;

  /// Courier codes that were requested.
  final List<String> courierCodes;

  /// Which page produced this entry.
  ShipmentType get type;

  /// The services returned by the API for this calculation.
  List<ShippingCost> get results;

  /// The cheapest service, or null when the API returned nothing.
  ///
  /// This loops instead of calling `reduce`. A subtype's real list is a
  /// `List<DomesticShippingCost>` or `List<InternationalShippingCost>`, and a
  /// `(ShippingCost, ShippingCost) => ShippingCost` callback fails the runtime
  /// type check of a covariant list.
  ShippingCost? get cheapest {
    ShippingCost? best;
    for (final result in results) {
      if (best == null || result.cost < best.cost) {
        best = result;
      }
    }
    return best;
  }

  /// Serializes this entry for device storage.
  Map<String, dynamic> toJson();

  Map<String, dynamic> _baseJson() => {
    'type': type.name,
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'origin_label': originLabel,
    'destination_label': destinationLabel,
    'weight_grams': weightGrams,
    'courier_codes': courierCodes,
  };

  static DateTime _readCreatedAt(Map<String, dynamic> json) {
    return DateTime.tryParse(readStringOr(json, 'created_at')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<String> _readCourierCodes(Map<String, dynamic> json) {
    final value = json['courier_codes'];
    if (value is List) {
      return value.map((code) => code.toString()).toList();
    }
    return const [];
  }
}

/// A saved calculation from the domestic page.
final class DomesticHistoryEntry extends ShippingHistoryEntry {
  const DomesticHistoryEntry({
    required super.id,
    required super.createdAt,
    required super.originLabel,
    required super.destinationLabel,
    required super.weightGrams,
    required super.courierCodes,
    required this.results,
  });

  /// Restores a domestic entry from storage.
  factory DomesticHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DomesticHistoryEntry(
      id: readString(json, 'id'),
      createdAt: ShippingHistoryEntry._readCreatedAt(json),
      originLabel: readStringOr(json, 'origin_label'),
      destinationLabel: readStringOr(json, 'destination_label'),
      weightGrams: readInt(json, 'weight_grams'),
      courierCodes: ShippingHistoryEntry._readCourierCodes(json),
      results: asJsonList(json['results'])
          .map(DomesticShippingCost.fromJson)
          .toList(),
    );
  }

  @override
  final List<DomesticShippingCost> results;

  @override
  ShipmentType get type => ShipmentType.domestic;

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'results': results.map((result) => result.toJson()).toList(),
  };
}

/// A saved calculation from the international page.
final class InternationalHistoryEntry extends ShippingHistoryEntry {
  const InternationalHistoryEntry({
    required super.id,
    required super.createdAt,
    required super.originLabel,
    required super.destinationLabel,
    required super.weightGrams,
    required super.courierCodes,
    required this.results,
  });

  /// Restores an international entry from storage.
  factory InternationalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InternationalHistoryEntry(
      id: readString(json, 'id'),
      createdAt: ShippingHistoryEntry._readCreatedAt(json),
      originLabel: readStringOr(json, 'origin_label'),
      destinationLabel: readStringOr(json, 'destination_label'),
      weightGrams: readInt(json, 'weight_grams'),
      courierCodes: ShippingHistoryEntry._readCourierCodes(json),
      results: asJsonList(json['results'])
          .map(InternationalShippingCost.fromJson)
          .toList(),
    );
  }

  @override
  final List<InternationalShippingCost> results;

  @override
  ShipmentType get type => ShipmentType.international;

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'results': results.map((result) => result.toJson()).toList(),
  };
}
