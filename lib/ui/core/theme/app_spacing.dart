/// Spacing scale.
///
/// Every step is a multiple of [spaceUnit], so layouts never use arbitrary
/// padding numbers.
abstract final class AppSpacing {
  /// Base unit the whole scale is derived from.
  static const double spaceUnit = 16;

  /// 4
  static const double xxs = 0.25 * spaceUnit;

  /// 6
  static const double xs = 0.375 * spaceUnit;

  /// 8
  static const double sm = 0.5 * spaceUnit;

  /// 12
  static const double md = 0.75 * spaceUnit;

  /// 16
  static const double lg = spaceUnit;

  /// 24
  static const double xlg = 1.5 * spaceUnit;

  /// 32
  static const double xxlg = 2 * spaceUnit;

  /// Largest content width before a page stops stretching on wide windows.
  static const double maxContentWidth = 720;
}
