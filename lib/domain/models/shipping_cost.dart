import 'package:flutter_mvvm_x_rajaongkir/utils/json_reader.dart';

/// One courier service returned by a calculate-cost endpoint.
///
/// The domestic and international endpoints share six fields and differ only in
/// the currency information, so this is a sealed hierarchy: the detail pop-ups
/// switch on the subtype to decide between a bottom sheet and a dialog, and the
/// compiler checks that both cases are handled.
sealed class ShippingCost {
  const ShippingCost({
    required this.name,
    required this.code,
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
  });

  /// Courier name, for example `Jalur Nugraha Ekakurir (JNE)`.
  final String name;

  /// Courier code, for example `jne`.
  final String code;

  /// Service name, for example `REG`.
  final String service;

  /// Service description, for example `Layanan Reguler`.
  final String description;

  /// Shipping cost in Rupiah.
  final int cost;

  /// Estimated time of delivery as returned by the API, for example `1-2 day`.
  ///
  /// It can also be an empty string or `-` when the courier gives no estimate.
  final String etd;

  /// First number found in [etd], used to sort by speed.
  ///
  /// Null when the API gave no usable estimate.
  int? get estimatedDays {
    final match = RegExp(r'\d+').firstMatch(etd);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0) ?? '');
  }

  /// The raw API attributes of this item, in the order the API documents them.
  ///
  /// The detail pop-ups render these as key-value rows, which is how the
  /// `description` attribute reaches the screen.
  Map<String, Object?> get apiAttributes;

  /// Serializes this item so it can be stored in the shipping history.
  Map<String, dynamic> toJson();
}

/// A result of the District Calculate Cost endpoint (step-by-step method).
final class DomesticShippingCost extends ShippingCost {
  const DomesticShippingCost({
    required super.name,
    required super.code,
    required super.service,
    required super.description,
    required super.cost,
    required super.etd,
  });

  /// Creates a domestic result from one item of the `data` array.
  factory DomesticShippingCost.fromJson(Map<String, dynamic> json) {
    return DomesticShippingCost(
      name: readString(json, 'name'),
      code: readString(json, 'code'),
      service: readString(json, 'service'),
      description: readStringOr(json, 'description'),
      cost: readInt(json, 'cost'),
      etd: readStringOr(json, 'etd'),
    );
  }

  @override
  Map<String, Object?> get apiAttributes => {
    'name': name,
    'code': code,
    'service': service,
    'description': description,
    'cost': cost,
    'etd': etd,
  };

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'service': service,
    'description': description,
    'cost': cost,
    'etd': etd,
  };

  @override
  String toString() => 'DomesticShippingCost($code, $service, $cost)';
}

/// A result of the International Calculate Cost endpoint (direct search
/// method).
///
/// `currency_updated_at` and `currency_value` are only sent by some couriers,
/// so both are nullable.
final class InternationalShippingCost extends ShippingCost {
  const InternationalShippingCost({
    required super.name,
    required super.code,
    required super.service,
    required super.description,
    required super.cost,
    required super.etd,
    required this.currency,
    this.currencyUpdatedAt,
    this.currencyValue,
  });

  /// Creates an international result from one item of the `data` array.
  factory InternationalShippingCost.fromJson(Map<String, dynamic> json) {
    return InternationalShippingCost(
      name: readString(json, 'name'),
      code: readString(json, 'code'),
      service: readString(json, 'service'),
      description: readStringOr(json, 'description'),
      cost: readInt(json, 'cost'),
      etd: readStringOr(json, 'etd'),
      currency: readStringOr(json, 'currency', fallback: 'IDR'),
      currencyUpdatedAt: readStringOrNull(json, 'currency_updated_at'),
      currencyValue: readIntOrNull(json, 'currency_value'),
    );
  }

  /// Currency of [cost], which the API reports as `IDR`.
  final String currency;

  /// Date the exchange rate was last updated, when the courier reports one.
  final String? currencyUpdatedAt;

  /// Exchange rate used by the courier, when it reports one.
  final int? currencyValue;

  @override
  Map<String, Object?> get apiAttributes => {
    'name': name,
    'code': code,
    'service': service,
    'description': description,
    'currency': currency,
    'cost': cost,
    'etd': etd,
    if (currencyUpdatedAt != null) 'currency_updated_at': currencyUpdatedAt,
    if (currencyValue != null) 'currency_value': currencyValue,
  };

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'service': service,
    'description': description,
    'currency': currency,
    'cost': cost,
    'etd': etd,
    'currency_updated_at': currencyUpdatedAt,
    'currency_value': currencyValue,
  };

  @override
  String toString() => 'InternationalShippingCost($code, $service, $cost)';
}
