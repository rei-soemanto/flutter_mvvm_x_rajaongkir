/// Build-time configuration for the application.
///
/// The API key is injected at build time so it never enters source control:
///
/// ```sh
/// flutter run --dart-define-from-file=config/env.json
/// ```
abstract final class AppConfig {
  /// Base URL of the RajaOngkir (Komerce) Shipping Cost API.
  static const String rajaOngkirBaseUrl =
      'https://rajaongkir.komerce.id/api/v1';

  /// Shipping Cost API key supplied with `--dart-define-from-file`.
  static const String rajaOngkirApiKey = String.fromEnvironment(
    'RAJAONGKIR_API_KEY',
  );

  /// Whether a non-empty API key was supplied at build time.
  static bool get hasApiKey => rajaOngkirApiKey.trim().isNotEmpty;

  /// Timeout applied to every network request.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// How long cached province, city and district lists stay valid.
  ///
  /// The free API plan allows 100 requests per day, so these rarely changing
  /// lookups are cached on the device.
  static const Duration regionCacheTtl = Duration(days: 7);

  /// Maximum number of saved calculations kept on the device.
  static const int historyLimit = 50;

  /// Delay applied to search-as-you-type fields.
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Minimum number of characters before a search request is sent.
  static const int minSearchLength = 3;
}
