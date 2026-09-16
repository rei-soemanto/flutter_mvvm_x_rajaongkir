import 'package:flutter/foundation.dart';

/// The three destinations of the bottom navigation bar.
enum AppTab {
  /// Step-by-step domestic calculation.
  domestic,

  /// Direct search international calculation.
  international,

  /// Saved calculations.
  history,
}

/// Holds which tab the navigation shell is showing.
///
/// Keeping the index here rather than in the widget means the navigation state
/// is part of the view model layer like every other piece of UI state, and it
/// can be set from a route.
class MainShellViewModel extends ChangeNotifier {
  MainShellViewModel({AppTab initialTab = AppTab.domestic})
    : _currentTab = initialTab;

  AppTab _currentTab;

  /// The tab currently in front.
  AppTab get currentTab => _currentTab;

  /// The tab index, as the bottom navigation bar expects it.
  int get currentIndex => _currentTab.index;

  /// Shows [tab].
  void selectTab(AppTab tab) {
    if (tab == _currentTab) {
      return;
    }
    _currentTab = tab;
    notifyListeners();
  }

  /// Shows the tab at [index].
  void selectIndex(int index) {
    if (index < 0 || index >= AppTab.values.length) {
      return;
    }
    selectTab(AppTab.values[index]);
  }
}
