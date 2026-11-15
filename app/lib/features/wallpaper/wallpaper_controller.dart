import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wallpapers.dart';

/// Holds the selected wallpaper and persists its id.
class WallpaperController extends ChangeNotifier {
  WallpaperController(this._prefs) : _id = _load(_prefs);

  static const String prefsKey = 'nuvio.wallpaper';

  final SharedPreferences _prefs;
  String _id;

  static String _load(SharedPreferences prefs) {
    String? stored;
    try {
      stored = prefs.getString(prefsKey);
    } catch (_) {
      stored = null;
    }
    return Wallpapers.byId(stored ?? Wallpapers.defaultId).id;
  }

  String get id => _id;
  Wallpaper get wallpaper => Wallpapers.byId(_id);

  Future<void> select(String id) async {
    final next = Wallpapers.byId(id).id;
    if (next == _id) return;
    _id = next;
    notifyListeners();
    await _prefs.setString(prefsKey, next);
  }
}
