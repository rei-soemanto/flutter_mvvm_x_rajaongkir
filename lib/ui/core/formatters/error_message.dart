/// Turns an exception into a sentence that can be shown to the user.
library;

import 'package:flutter_mvvm_x_rajaongkir/data/services/rajaongkir/api_exception.dart';

/// Returns the user-facing message for [error].
///
/// Data layer failures already carry one; anything else falls back to a short
/// generic sentence so raw exception text never reaches the screen.
String describeError(Object? error) {
  if (error is ApiException) {
    return error.userMessage;
  }
  if (error == null) {
    return 'Something went wrong. Please try again.';
  }
  return 'Something went wrong: $error';
}
