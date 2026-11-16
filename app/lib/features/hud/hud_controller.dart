import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hud_models.dart';

/// State and persistence of the on-screen HUD (visibility, layout, edit mode, auto-hide).
class HudController extends ChangeNotifier {
  HudController(this._prefs)
      : _layout = HudLayout.decode(_prefs.getString(_kLayout)),
        _hidden = _prefs.getBool(_kHidden) ?? false,
        _opacity = (_prefs.getDouble(_kOpacity) ?? 0.75).clamp(0.2, 1.0),
        _scale = (_prefs.getDouble(_kScale) ?? 1.0).clamp(0.6, 1.6),
        _autoHide = _prefs.getBool(_kAutoHide) ?? true;

  static const _kLayout = 'nuvio.hud.layout';
  static const _kHidden = 'nuvio.hud.hidden';
  static const _kOpacity = 'nuvio.hud.opacity';
  static const _kScale = 'nuvio.hud.scale';
  static const _kAutoHide = 'nuvio.hud.autohide';

  final SharedPreferences _prefs;
  HudLayout _layout;
  bool _hidden;
  double _opacity;
  double _scale;
  bool _autoHide;
  bool _editMode = false;
  bool _physicalActive = false;
  String? _selectedId;

  HudLayout get layout => _layout;
  bool get hidden => _hidden;
  double get opacity => _opacity;
  double get scale => _scale;
  bool get autoHide => _autoHide;
  bool get editMode => _editMode;
  bool get physicalActive => _physicalActive;
  String? get selectedId => _selectedId;
  HudButton? get selected {
    for (final b in _layout.buttons) {
      if (b.id == _selectedId) return b;
    }
    return null;
  }

  /// The buttons are shown unless hidden by the user or a physical keyboard/mouse is in use.
  /// In edit mode they are always shown.
  bool get showButtons => _editMode || (!_hidden && !(_autoHide && _physicalActive));

  void _save() {
    _prefs.setString(_kLayout, _layout.encode());
    _prefs.setBool(_kHidden, _hidden);
    _prefs.setDouble(_kOpacity, _opacity);
    _prefs.setDouble(_kScale, _scale);
    _prefs.setBool(_kAutoHide, _autoHide);
  }

  void toggleHidden() {
    _hidden = !_hidden;
    _save();
    notifyListeners();
  }

  void setOpacity(double v) {
    _opacity = v.clamp(0.2, 1.0);
    _save();
    notifyListeners();
  }

  void setScale(double v) {
    _scale = v.clamp(0.6, 1.6);
    _save();
    notifyListeners();
  }

  void setAutoHide(bool v) {
    _autoHide = v;
    _save();
    notifyListeners();
  }

  void setEditMode(bool v) {
    _editMode = v;
    if (!v) _selectedId = null;
    notifyListeners();
  }

  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  /// Called when a hardware keyboard or mouse produced input.
  void physicalInputSeen() {
    if (_physicalActive) return;
    _physicalActive = true;
    notifyListeners();
  }

  /// Called when a genuine finger touch happened (not a mouse echo): bring the HUD back.
  void touchSeen() {
    if (!_physicalActive) return;
    _physicalActive = false;
    notifyListeners();
  }

  void _update(String id, HudButton Function(HudButton) f) {
    _layout = _layout.map((b) => b.id == id ? f(b) : b);
    _save();
    notifyListeners();
  }

  void moveButton(String id, double x, double y) =>
      _update(id, (b) => b.copyWith(x: x.clamp(0.0, 1.0), y: y.clamp(0.0, 1.0)));

  void resizeButton(String id, double size) =>
      _update(id, (b) => b.copyWith(size: size.clamp(32.0, 120.0)));

  void setButtonVisible(String id, bool visible) => _update(id, (b) => b.copyWith(visible: visible));

  void resetLayout() {
    _layout = HudLayout.defaults();
    _selectedId = null;
    _save();
    notifyListeners();
  }
}
