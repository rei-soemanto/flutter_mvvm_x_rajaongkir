/// Turns the raw attributes of a calculate-cost response item into rows.
///
/// The assignment asks for every attribute of the response, including
/// `description`, to be shown in a pop-up. Both pop-ups build their rows here so
/// the domestic bottom sheet and the international dialog stay consistent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_cost.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/etd_formatter.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/key_value_row.dart';

/// Human readable label for each attribute key the API can send.
const Map<String, String> costAttributeLabels = {
  'name': 'Courier',
  'code': 'Courier code',
  'service': 'Service',
  'description': 'Description',
  'currency': 'Currency',
  'cost': 'Cost',
  'etd': 'Estimated delivery',
  'currency_updated_at': 'Exchange rate updated',
  'currency_value': 'Exchange rate',
};

/// The label registered for [key], or the key itself when it is unknown.
String costAttributeLabel(String key) => costAttributeLabels[key] ?? key;

/// Formats the raw [value] of attribute [key] for display.
String formatCostAttribute(String key, Object? value, String currency) {
  if (value == null) {
    return 'Not provided';
  }

  switch (key) {
    case 'cost':
      final amount = value is num
          ? value.toInt()
          : int.tryParse(value.toString()) ?? 0;
      return formatMoney(amount, currency);
    case 'etd':
      return formatEtd(value.toString());
    case 'code':
      return value.toString().toUpperCase();
    case 'currency_value':
      return value is num ? formatNumber(value) : value.toString();
    default:
      final text = value.toString().trim();
      return text.isEmpty ? 'Not provided' : text;
  }
}

/// Builds one [KeyValueRow] per attribute of [cost], in the order the API
/// documents them.
List<Widget> buildCostAttributeRows(ShippingCost cost) {
  final currency = switch (cost) {
    InternationalShippingCost(:final currency) => currency,
    DomesticShippingCost() => 'IDR',
  };

  return cost.apiAttributes.entries
      .map(
        (entry) => KeyValueRow(
          label: costAttributeLabel(entry.key),
          apiKey: entry.key,
          value: formatCostAttribute(entry.key, entry.value, currency),
        ),
      )
      .toList();
}
