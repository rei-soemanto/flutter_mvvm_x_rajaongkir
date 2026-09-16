import 'dart:async';

/// Delays an action until the input has been quiet for [duration].
///
/// Search-as-you-type fields use this to keep the daily API quota low. A zero
/// duration runs the action immediately, which keeps tests synchronous.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 500)});

  /// How long to wait after the last call before running the action.
  final Duration duration;

  Timer? _timer;

  /// Schedules [action], replacing any action that is still pending.
  void run(void Function() action) {
    _timer?.cancel();
    if (duration == Duration.zero) {
      action();
      return;
    }
    _timer = Timer(duration, action);
  }

  /// Cancels a pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
