import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/features/wallpaper/wallpaper_controller.dart';
import 'package:nuvio_launcher/features/wallpaper/wallpapers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to overworld_night', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(WallpaperController(prefs).id, 'overworld_night');
  });

  test('persists the selected wallpaper', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = WallpaperController(prefs);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.select('the_end');
    expect(controller.id, 'the_end');
    expect(notified, 1);
    expect(prefs.getString(WallpaperController.prefsKey), 'the_end');
    expect(WallpaperController(prefs).id, 'the_end');
  });

  test('unknown ids fall back to the default', () async {
    SharedPreferences.setMockInitialValues({WallpaperController.prefsKey: 'nope'});
    final prefs = await SharedPreferences.getInstance();
    final controller = WallpaperController(prefs);
    expect(controller.id, Wallpapers.all.first.id);
    await controller.select('also_nope');
    expect(controller.id, Wallpapers.all.first.id);
  });

  test('forSeed is deterministic and covers valid wallpapers', () {
    expect(Wallpapers.forSeed('abc').id, Wallpapers.forSeed('abc').id);
    expect(Wallpapers.all.map((w) => w.id), contains(Wallpapers.forSeed('xyz').id));
    expect(Wallpapers.all, hasLength(8));
  });
}
