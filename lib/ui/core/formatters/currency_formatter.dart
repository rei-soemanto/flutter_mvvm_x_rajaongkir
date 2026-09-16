/// Formats money values for display.
library;

import 'package:intl/intl.dart';

final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

final NumberFormat _plainNumber = NumberFormat.decimalPattern('id_ID');

/// Formats [amount] as Rupiah, for example `Rp10.000`.
String formatRupiah(int amount) => _rupiah.format(amount);

/// Formats [amount] in the currency the API reported.
///
/// The international endpoint reports `IDR` today, but it sends the currency
/// per result, so anything else is shown with its code in front.
String formatMoney(int amount, String currency) {
  final code = currency.trim().toUpperCase();
  if (code.isEmpty || code == 'IDR') {
    return formatRupiah(amount);
  }
  return '$code ${_plainNumber.format(amount)}';
}

/// Formats a plain number with thousands separators.
String formatNumber(num value) => _plainNumber.format(value);

/// Formats a parcel weight, for example `500 g` or `1,5 kg`.
String formatWeight(int grams) {
  if (grams < 1000) {
    return '$grams g';
  }
  final kilograms = grams / 1000;
  final text = grams % 1000 == 0
      ? kilograms.toStringAsFixed(0)
      : _plainNumber.format(kilograms);
  return '$text kg';
}
