/// A bundled wallpaper (full image + small thumbnail).
class Wallpaper {
  const Wallpaper(this.id, this.label);

  final String id;

  /// Indonesian display name.
  final String label;

  String get asset => 'assets/wallpapers/$id.jpg';
  String get thumbAsset => 'assets/wallpapers/${id}_thumb.jpg';
}

/// The fixed set of wallpapers; custom images are intentionally not supported.
abstract final class Wallpapers {
  static const String defaultId = 'overworld_night';

  static const List<Wallpaper> all = [
    Wallpaper('overworld_night', 'Malam Overworld'),
    Wallpaper('cherry_grove', 'Hutan Sakura'),
    Wallpaper('desert_sunset', 'Senja Gurun'),
    Wallpaper('snow_aurora', 'Aurora Salju'),
    Wallpaper('nether_lava', 'Lava Nether'),
    Wallpaper('the_end', 'The End'),
    Wallpaper('crystal_cave', 'Gua Kristal'),
    Wallpaper('island_dusk', 'Pulau Senja'),
  ];

  /// Wallpaper for [id], or the default when unknown.
  static Wallpaper byId(String? id) => all.firstWhere(
        (w) => w.id == id,
        orElse: () => all.first,
      );

  /// Deterministic wallpaper for any seed (e.g. an instance id).
  static Wallpaper forSeed(String seed) {
    var h = 7;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return all[h % all.length];
  }
}
