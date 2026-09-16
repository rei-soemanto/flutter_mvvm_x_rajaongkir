/// Formats the `etd` field of a calculate-cost response.
///
/// The API sends values such as `1-2 day`, `1 day`, `-` or an empty string.
library;

final RegExp _dayWord = RegExp(r'\s*(days?|hari)\s*$', caseSensitive: false);

/// Turns a raw `etd` value into something readable.
///
/// Returns `Not specified` when the courier gave no estimate.
String formatEtd(String etd) {
  final value = etd.trim();
  if (value.isEmpty || value == '-') {
    return 'Not specified';
  }

  final amount = value.replaceAll(_dayWord, '').trim();
  if (amount.isEmpty) {
    return 'Not specified';
  }

  return amount == '1' ? '1 day' : '$amount days';
}
