import 'package:flutter/foundation.dart';

/// Tabs of the main shell.
abstract final class AppTab {
  static const int home = 0;
  static const int instances = 1;
  static const int versions = 2;
  static const int content = 3;
  static const int accounts = 4;
  static const int license = 5;
  static const int settings = 6;
}

/// Lets any page switch the active tab (e.g. "Get Nuvio Plus").
class NavigationController extends ChangeNotifier {
  int _index = AppTab.home;

  int get index => _index;

  void go(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}
