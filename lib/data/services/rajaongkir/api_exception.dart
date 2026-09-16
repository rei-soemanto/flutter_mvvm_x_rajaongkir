/// Failures raised by the data layer.
///
/// Every exception carries a [userMessage] the UI can show without knowing
/// anything about HTTP.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  /// Technical description, usually the message returned in `meta.message`.
  final String message;

  /// HTTP status or `meta.code` when the failure came from the server.
  final int? statusCode;

  /// The original error, when this exception wraps one.
  final Object? cause;

  /// A sentence that can be shown to the user.
  String get userMessage => message;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return '$runtimeType$code: $message';
  }
}

/// No API key was supplied at build time.
class MissingApiKeyException extends ApiException {
  const MissingApiKeyException()
    : super('RAJAONGKIR_API_KEY was not supplied at build time');

  @override
  String get userMessage =>
      'No API key found. Copy config/env.example.json to config/env.json, add '
      'your Shipping Cost key, and run with '
      '--dart-define-from-file=config/env.json.';
}

/// The server answered with a non-success status or `meta.code`.
class ApiHttpException extends ApiException {
  const ApiHttpException(super.message, {required int super.statusCode});

  /// Chooses the most specific subclass for [statusCode].
  factory ApiHttpException.fromStatus(int statusCode, String message) {
    return switch (statusCode) {
      400 || 401 || 403 => UnauthorizedException(message, statusCode),
      404 => NotFoundException(message),
      422 => ValidationException(message),
      429 => TooManyRequestsException(message),
      >= 500 && < 600 => ServerException(message, statusCode),
      _ => ApiHttpException(message, statusCode: statusCode),
    };
  }

  @override
  String get userMessage => 'The server rejected the request: $message';
}

/// The API key is missing, wrong or not allowed.
///
/// RajaOngkir answers 401 when no key is sent and 400 when the key is invalid,
/// so both map here.
class UnauthorizedException extends ApiHttpException {
  const UnauthorizedException(super.message, int statusCode)
    : super(statusCode: statusCode);

  @override
  String get userMessage =>
      'The RajaOngkir API rejected the key ($message). Check the value in '
      'config/env.json.';
}

/// Nothing matched the request.
class NotFoundException extends ApiHttpException {
  const NotFoundException(super.message) : super(statusCode: 404);

  @override
  String get userMessage => 'Not found: $message';
}

/// The request was missing or had invalid parameters.
class ValidationException extends ApiHttpException {
  const ValidationException(super.message) : super(statusCode: 422);

  @override
  String get userMessage => 'The request was rejected: $message';
}

/// The daily quota was exhausted.
class TooManyRequestsException extends ApiHttpException {
  const TooManyRequestsException(super.message) : super(statusCode: 429);

  @override
  String get userMessage =>
      'Too many requests. The free plan allows 100 calls per day, so try again '
      'later.';
}

/// The server failed to answer the request.
class ServerException extends ApiHttpException {
  const ServerException(super.message, int statusCode)
    : super(statusCode: statusCode);

  @override
  String get userMessage => 'The server had a problem. Try again in a moment.';
}

/// The request never reached the server.
class ApiNetworkException extends ApiException {
  const ApiNetworkException(super.message, {super.cause});

  @override
  String get userMessage =>
      'No connection to the RajaOngkir server. Check your internet connection.';
}

/// The request took longer than the configured timeout.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, {super.cause});

  @override
  String get userMessage => 'The request timed out. Try again.';
}

/// The response body was not the JSON the app expected.
class ApiDecodeException extends ApiException {
  const ApiDecodeException(super.message, {super.cause});

  @override
  String get userMessage => 'The server sent an unexpected response.';
}

/// Reading or writing device storage failed.
class StorageException extends ApiException {
  const StorageException(super.message, {super.cause});

  @override
  String get userMessage => 'Could not read the data saved on this device.';
}
