/// A courier that can be selected before calculating a cost.
///
/// Codes are joined with `:` when they are sent to the API, for example
/// `jne:pos:tiki`.
class Courier {
  const Courier({required this.code, required this.label});

  /// Code the API expects, for example `jne`.
  final String code;

  /// Human readable name shown on the selection chips.
  final String label;

  /// Couriers accepted by the domestic calculate-cost endpoints.
  static const List<Courier> domestic = [
    Courier(code: 'jne', label: 'JNE'),
    Courier(code: 'sicepat', label: 'SiCepat'),
    Courier(code: 'jnt', label: 'J&T Express'),
    Courier(code: 'pos', label: 'POS Indonesia'),
    Courier(code: 'tiki', label: 'TIKI'),
    Courier(code: 'anteraja', label: 'AnterAja'),
    Courier(code: 'ninja', label: 'Ninja Xpress'),
    Courier(code: 'lion', label: 'Lion Parcel'),
    Courier(code: 'ide', label: 'ID Express'),
    Courier(code: 'sap', label: 'SAP Express'),
    Courier(code: 'ncs', label: 'NCS'),
    Courier(code: 'rex', label: 'REX'),
    Courier(code: 'rpx', label: 'RPX'),
    Courier(code: 'sentral', label: 'Sentral Cargo'),
    Courier(code: 'star', label: 'Star Cargo'),
    Courier(code: 'wahana', label: 'Wahana'),
    Courier(code: 'dse', label: 'DSE'),
  ];

  /// Couriers accepted by the international calculate-cost endpoint.
  static const List<Courier> international = [
    Courier(code: 'pos', label: 'POS Indonesia'),
    Courier(code: 'jne', label: 'JNE'),
    Courier(code: 'tiki', label: 'TIKI'),
    Courier(code: 'lion', label: 'Lion Parcel'),
    Courier(code: 'expedito', label: 'Expedito'),
    Courier(code: 'ray', label: 'Rayspeed'),
  ];

  /// Couriers selected by default on the domestic page.
  static const Set<String> defaultDomesticCodes = {'jne', 'pos', 'tiki'};

  /// Couriers selected by default on the international page.
  static const Set<String> defaultInternationalCodes = {'pos', 'jne', 'tiki'};

  /// The label registered for [code], or the code itself in upper case.
  static String labelFor(String code) {
    for (final courier in [...domestic, ...international]) {
      if (courier.code == code) {
        return courier.label;
      }
    }
    return code.toUpperCase();
  }

  @override
  bool operator ==(Object other) => other is Courier && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Courier($code)';
}
