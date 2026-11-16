import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/data/models/instance.dart';
import 'package:nuvio_launcher/data/services/content/modpack_installer.dart';

void main() {
  test('parses a Modrinth index', () {
    final plan = ModpackInstaller.parseModrinth({
      'name': 'Cool Pack',
      'dependencies': {'minecraft': '1.20.1', 'fabric-loader': '0.15.11'},
      'files': [
        {'path': 'mods/a.jar', 'hashes': {'sha1': 'abc'}, 'downloads': ['https://x/a.jar']},
        {'path': 'mods/server.jar', 'env': {'client': 'unsupported'}, 'downloads': ['https://x/s.jar']},
      ],
    });
    expect(plan.mcVersion, '1.20.1');
    expect(plan.loader, LoaderType.fabric);
    expect(plan.loaderVersion, '0.15.11');
    expect(plan.files.map((f) => f.path), ['mods/a.jar']);
  });

  test('parses a CurseForge manifest', () {
    final m = ModpackInstaller.parseCurseForge({
      'name': 'CF Pack',
      'minecraft': {
        'version': '1.20.1',
        'modLoaders': [{'id': 'forge-47.2.0', 'primary': true}],
      },
      'files': [
        {'projectID': 1, 'fileID': 2, 'required': true},
        {'projectID': 3, 'fileID': 4, 'required': false},
      ],
      'overrides': 'overrides',
    });
    expect(m.loader, LoaderType.forge);
    expect(m.loaderVersion, '47.2.0');
    expect(m.files.length, 1);
  });

  test('rejects path traversal', () {
    expect(ModpackInstaller.safeSegments('../evil.jar'), isNull);
    expect(ModpackInstaller.safeSegments('C:/evil.jar'), isNull);
    expect(ModpackInstaller.safeSegments('mods/ok.jar'), ['mods', 'ok.jar']);
  });
}
