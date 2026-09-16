import 'package:flutter/foundation.dart';
import 'package:flutter_mvvm_x_rajaongkir/utils/result.dart';

/// An action without arguments that a view can run.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// An action with one argument that a view can run.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// Encapsulates an action triggered by a view.
///
/// A command exposes its running and error state and refuses to start again
/// while it is still running, which stops a double tap from sending two
/// requests. Adapted from the `flutter-architecture` skill template; the
/// template's `bool error` getter is split here into [failed] and [error] so
/// the failure reason is available to the view.
///
/// Use commands for one-shot actions. Do not use them for debounced search,
/// where a newer call must supersede the running one instead of being dropped.
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;

  /// Whether the action is currently running.
  bool get running => _running;

  Result<T>? _result;

  /// The result of the last run, or null when it never ran or was cleared.
  Result<T>? get result => _result;

  /// Whether the last run failed.
  bool get failed => _result is Failure;

  /// Whether the last run succeeded.
  bool get completed => _result is Ok;

  /// The exception of the last run, or null when it did not fail.
  Exception? get error => _result?.errorOrNull;

  /// Forgets the last result, for example after showing an error.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) {
      return;
    }
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] that takes no argument.
class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Runs the action.
  Future<void> execute() => _execute(_action);
}

/// A [Command] that takes one argument.
class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Runs the action with [argument].
  Future<void> execute(A argument) => _execute(() => _action(argument));
}
