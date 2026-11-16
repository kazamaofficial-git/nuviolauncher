import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/data/services/game_launcher/loaders/loader_installer.dart';
import 'package:nuvio_launcher/data/services/game_launcher/loaders/version_merge.dart';

void main() {
  test('child libraries win and arguments are concatenated', () {
    final parent = {
      'id': '1.21',
      'mainClass': 'net.minecraft.client.main.Main',
      'libraries': [
        {'name': 'org.ow2.asm:asm:9.2'},
        {'name': 'com.mojang:brigadier:1.0'},
      ],
      'arguments': {'jvm': ['-cp', r'${classpath}'], 'game': ['--username']},
      'assetIndex': {'id': '17'},
    };
    final child = {
      'id': 'fabric-loader-0.16-1.21',
      'inheritsFrom': '1.21',
      'mainClass': 'net.fabricmc.loader.impl.launch.knot.KnotClient',
      'libraries': [
        {'name': 'org.ow2.asm:asm:9.7'},
      ],
      'arguments': {'jvm': ['-DFabricMcEmu='], 'game': <String>[]},
    };
    final merged = mergeVersionJson(parent, child);
    expect(merged.containsKey('inheritsFrom'), isFalse);
    expect(merged['mainClass'], contains('Knot'));
    final libs = (merged['libraries'] as List).map((e) => (e as Map)['name']).toList();
    expect(libs, ['org.ow2.asm:asm:9.7', 'com.mojang:brigadier:1.0']);
    expect((merged['arguments'] as Map)['jvm'], ['-cp', r'${classpath}', '-DFabricMcEmu=']);
    expect(merged['assetIndex'], {'id': '17'});
  });

  test('neoforge version prefix', () {
    expect(LoaderInstaller.neoforgePrefix('1.21.1'), '21.1.');
    expect(LoaderInstaller.neoforgePrefix('1.21'), '21.0.');
    expect(LoaderInstaller.neoforgePrefix('1.20.4'), '20.4.');
    expect(LoaderInstaller.neoforgePrefix('1.20.1'), isNull);
    expect(LoaderInstaller.neoforgePrefix('1.16.5'), isNull);
  });
}
