/// Paths of the RajaOngkir Shipping Cost API, relative to
/// `AppConfig.rajaOngkirBaseUrl`.
///
/// The first group belongs to the step-by-step method and the second to the
/// direct search method.
abstract final class RajaOngkirEndpoints {
  /// Search Province.
  static const String provinces = '/destination/province';

  /// Search City, by province id.
  static String cities(int provinceId) => '/destination/city/$provinceId';

  /// Search District, by city id.
  static String districts(int cityId) => '/destination/district/$cityId';

  /// District Calculate Cost. Expects district ids.
  static const String districtDomesticCost =
      '/calculate/district/domestic-cost';

  /// Search Domestic Destination.
  static const String domesticDestinations =
      '/destination/domestic-destination';

  /// Search International Destination.
  static const String internationalDestinations =
      '/destination/international-destination';

  /// Calculate International Cost.
  static const String internationalCost = '/calculate/international-cost';
}
