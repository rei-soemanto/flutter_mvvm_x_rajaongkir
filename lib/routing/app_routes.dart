/// Names of the routes the app can push.
abstract final class AppRoutes {
  /// The navigation shell, opened on the domestic tab.
  static const String home = '/';

  /// The shell, opened on the domestic tab.
  static const String domestic = '/domestic';

  /// The shell, opened on the international tab.
  static const String international = '/international';

  /// The shell, opened on the history tab.
  static const String history = '/history';

  /// One saved calculation. Takes the entry id as its route argument.
  static const String historyDetail = '/history/detail';
}
