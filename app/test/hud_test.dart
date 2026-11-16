import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/features/hud/hud_controller.dart';
import 'package:nuvio_launcher/features/hud/hud_models.dart';
import 'package:nuvio_launcher/features/hud/input_sink.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PointerDeduper', () {
    test('drops a touch echo right after a mouse event at the same spot', () {
      final d = PointerDeduper();
      const pos = Offset(100, 100);
      expect(d.accept(PointerDeviceKind.mouse, pos, const Duration(milliseconds: 1000)), isTrue);
      expect(d.accept(PointerDeviceKind.touch, pos + const Offset(1, 1), const Duration(milliseconds: 1020)), isFalse);
    });

    test('keeps real touches elsewhere or later', () {
      final d = PointerDeduper();
      d.accept(PointerDeviceKind.mouse, const Offset(100, 100), const Duration(milliseconds: 1000));
      expect(d.accept(PointerDeviceKind.touch, const Offset(400, 300), const Duration(milliseconds: 1020)), isTrue);
      expect(d.accept(PointerDeviceKind.touch, const Offset(100, 100), const Duration(milliseconds: 1500)), isTrue);
    });
  });

  test('KeyDeduper sends each key once down and once up', () {
    final k = KeyDeduper();
    expect(k.down(87), isTrue);
    expect(k.down(87), isFalse);
    expect(k.up(87), isTrue);
    expect(k.up(87), isFalse);
  });

  group('HudController', () {
    late HudController hud;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      hud = HudController(await SharedPreferences.getInstance());
    });

    test('hides with physical input and returns on touch', () {
      expect(hud.showButtons, isTrue);
      hud.physicalInputSeen();
      expect(hud.showButtons, isFalse);
      hud.touchSeen();
      expect(hud.showButtons, isTrue);
    });

    test('auto-hide can be turned off and manual hide wins', () {
      hud.setAutoHide(false);
      hud.physicalInputSeen();
      expect(hud.showButtons, isTrue);
      hud.toggleHidden();
      expect(hud.showButtons, isFalse);
      hud.setEditMode(true);
      expect(hud.showButtons, isTrue, reason: 'edit mode always shows buttons');
    });

    test('move, hide and reset a button', () {
      hud.moveButton('jump', 0.3, 0.4);
      expect(hud.layout.buttons.firstWhere((b) => b.id == 'jump').x, 0.3);
      hud.setButtonVisible('jump', false);
      hud.resetLayout();
      final jump = hud.layout.buttons.firstWhere((b) => b.id == 'jump');
      expect(jump.visible, isTrue);
      expect(jump.x, isNot(0.3));
    });
  });

  test('layout survives a JSON round trip and bad input', () {
    final l = HudLayout.defaults();
    expect(HudLayout.decode(l.encode()).buttons.length, l.buttons.length);
    expect(HudLayout.decode('not json').buttons, isNotEmpty);
  });
}
