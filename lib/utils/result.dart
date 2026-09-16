/// Wraps the outcome of an operation so failures travel as values instead of
/// thrown exceptions.
///
/// Adapted from the `flutter-architecture` skill template: the template names
/// the failure case `Error`, which shadows `dart:core`'s `Error` type, so it is
/// called [Failure] here.
///
/// Evaluate a result with a switch:
///
/// ```dart
/// switch (result) {
///   case Ok<int>():
///     print(result.value);
///   case Failure<int>():
///     print(result.error);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Creates a failed result holding [error].
  const factory Result.failure(Exception error) = Failure<T>;

  /// Casts this result to [Ok]. Only call it after checking the type.
  Ok<T> get asOk => this as Ok<T>;

  /// Casts this result to [Failure]. Only call it after checking the type.
  Failure<T> get asFailure => this as Failure<T>;

  /// The value when this result succeeded, otherwise null.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Failure<T>() => null,
  };

  /// The error when this result failed, otherwise null.
  Exception? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Failure<T>(:final error) => error,
  };
}

/// A successful [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The value returned by the operation.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A failed [Result].
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  /// The exception that ended the operation.
  final Exception error;

  @override
  String toString() => 'Result<$T>.failure($error)';
}
