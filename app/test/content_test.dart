import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuvio_launcher/data/models/content/content_models.dart';
import 'package:nuvio_launcher/data/models/instance.dart';
import 'package:nuvio_launcher/data/services/content/content_installer.dart';
import 'package:nuvio_launcher/data/services/content/curseforge_client.dart';
import 'package:nuvio_launcher/data/services/content/hash_verifier.dart';
import 'package:nuvio_launcher/data/services/content/modrinth_client.dart';
import 'package:path/path.dart' as p;

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('Modrinth', () {
    final searchBody = {
      'hits': [
        {
          'project_id': 'AABBCCDD',
          'slug': 'sodium',
          'project_type': 'mod',
          'title': 'Sodium',
          'author': 'jellysquid3',
          'description': 'A fast renderer',
          'icon_url': 'https://cdn.example/sodium.png',
          'downloads': 1234567,
        },
        {'slug': 'broken'},
      ],
      'offset': 0,
      'limit': 20,
      'total_hits': 41,
    };

    test('parseSearch maps hits and skips entries without id', () {
      final r = ModrinthClient.parseSearch(searchBody, ContentCategory.mod);
      expect(r.projects, hasLength(1));
      final project = r.projects.first;
      expect(project.id, 'AABBCCDD');
      expect(project.title, 'Sodium');
      expect(project.author, 'jellysquid3');
      expect(project.downloads, 1234567);
      expect(project.iconUrl, 'https://cdn.example/sodium.png');
      expect(project.pageUrl, 'https://modrinth.com/mod/sodium');
      expect(r.total, 41);
      expect(r.hasMore, isTrue);
    });

    test('search sends facets for category, version and loader', () async {
      late Uri seen;
      final client = MockClient((req) async {
        seen = req.url;
        expect(req.headers['User-Agent'], startsWith('KazamaTech/NuvioLauncher/'));
        return _json(searchBody);
      });
      final modrinth = ModrinthClient(client: client, appVersion: '1.0.0');
      await modrinth.search(const ContentQuery(
        category: ContentCategory.mod,
        text: 'sod',
        gameVersion: '1.21',
        loader: LoaderType.fabric,
      ));
      final facets = jsonDecode(seen.queryParameters['facets']!) as List<dynamic>;
      expect(facets, [
        ['project_type:mod'],
        ['versions:1.21'],
        ['categories:fabric'],
      ]);
      expect(seen.queryParameters['query'], 'sod');
    });

    test('loader facet is ignored for non-mod categories', () {
      final facets = ModrinthClient.buildFacets(const ContentQuery(
        category: ContentCategory.shader,
        loader: LoaderType.fabric,
      ));
      expect(jsonDecode(facets), [
        ['project_type:shader'],
      ]);
    });

    test('parseVersions picks the primary file and hashes', () {
      final versions = ModrinthClient.parseVersions([
        {
          'id': 'v1',
          'name': 'Sodium 0.6',
          'version_number': '0.6.0',
          'game_versions': ['1.21', '1.21.1'],
          'loaders': ['fabric'],
          'date_published': '2024-09-01T10:00:00Z',
          'files': [
            {
              'filename': 'extra.jar',
              'url': 'https://cdn.example/extra.jar',
              'primary': false,
              'hashes': {'sha1': 'aa'},
            },
            {
              'filename': 'sodium.jar',
              'url': 'https://cdn.example/sodium.jar',
              'primary': true,
              'size': 99,
              'hashes': {'sha1': 'abc', 'sha512': 'def'},
            },
          ],
        },
      ]);
      expect(versions, hasLength(1));
      final v = versions.first;
      expect(v.gameVersions, ['1.21', '1.21.1']);
      expect(v.loaders, ['fabric']);
      expect(v.file!.filename, 'sodium.jar');
      expect(v.file!.sha1, 'abc');
      expect(v.file!.sha512, 'def');
      expect(v.file!.size, 99);
      expect(v.datePublished, isNotNull);
    });

    test('HTTP errors become ContentException', () async {
      final modrinth = ModrinthClient(
        client: MockClient((_) async => http.Response('nope', 500)),
        appVersion: '1.0.0',
      );
      expect(
        modrinth.search(const ContentQuery(category: ContentCategory.mod)),
        throwsA(isA<ContentException>()),
      );
    });
  });

  group('CurseForge', () {
    test('parseSearch maps mods', () {
      final r = CurseForgeClient.parseSearch({
        'data': [
          {
            'id': 306612,
            'name': 'Fabric API',
            'slug': 'fabric-api',
            'summary': 'Core library',
            'downloadCount': 5000,
            'authors': [
              {'name': 'modmuss50'},
            ],
            'logo': {'thumbnailUrl': 'https://cdn.example/t.png', 'url': 'https://cdn.example/f.png'},
            'links': {'websiteUrl': 'https://www.curseforge.com/minecraft/mc-mods/fabric-api'},
          },
        ],
        'pagination': {'index': 0, 'pageSize': 20, 'resultCount': 1, 'totalCount': 1},
      }, ContentCategory.mod);
      expect(r.projects.single.id, '306612');
      expect(r.projects.single.author, 'modmuss50');
      expect(r.projects.single.iconUrl, 'https://cdn.example/t.png');
      expect(r.projects.single.downloads, 5000);
      expect(r.hasMore, isFalse);
    });

    test('parseFiles keeps a null downloadUrl as null', () {
      final versions = CurseForgeClient.parseFiles({
        'data': [
          {
            'id': 1,
            'displayName': 'Pack 1.0',
            'fileName': 'pack-1.0.jar',
            'downloadUrl': null,
            'fileLength': 10,
            'gameVersions': ['1.21', 'Fabric', 'Client'],
            'hashes': [
              {'value': 'abc123', 'algo': 1},
              {'value': 'md5value', 'algo': 2},
            ],
          },
          {
            'id': 2,
            'displayName': 'Pack 1.1',
            'fileName': 'pack-1.1.jar',
            'downloadUrl': 'https://edge.example/pack-1.1.jar',
            'gameVersions': ['1.21.1', 'NeoForge'],
            'hashes': [],
          },
        ],
      });
      expect(versions, hasLength(2));
      expect(versions[0].file!.url, isNull);
      expect(versions[0].file!.sha1, 'abc123');
      expect(versions[0].gameVersions, ['1.21']);
      expect(versions[0].loaders, ['fabric']);
      expect(versions[1].file!.url, 'https://edge.example/pack-1.1.jar');
      expect(versions[1].file!.sha1, isNull);
      expect(versions[1].loaders, ['neoforge']);
    });

    test('search sends the API key and class id', () async {
      late http.BaseRequest seen;
      final client = MockClient((req) async {
        seen = req;
        return _json({'data': [], 'pagination': {'index': 0, 'totalCount': 0}});
      });
      final cf = CurseForgeClient(client: client, apiKey: 'KEY', appVersion: '1.0.0');
      await cf.search(const ContentQuery(category: ContentCategory.world));
      expect(seen.headers['x-api-key'], 'KEY');
      expect(seen.url.queryParameters['classId'], '17');
      expect(seen.url.queryParameters['gameId'], '432');
    });

    test('stripHtml removes tags and entities', () {
      expect(CurseForgeClient.stripHtml('<p>A &amp; B</p><p>C</p>'), 'A & B\nC');
    });
  });

  group('HashVerifier', () {
    final bytes = utf8.encode('hello');
    final sha1 = crypto.sha1.convert(bytes).toString();
    final sha512 = crypto.sha512.convert(bytes).toString();

    test('accepts matching hashes (case-insensitive) and skips empty ones', () {
      expect(HashVerifier.verifyBytes(bytes, sha1: sha1, sha512: sha512), isNull);
      expect(HashVerifier.verifyBytes(bytes, sha1: sha1.toUpperCase()), isNull);
      expect(HashVerifier.verifyBytes(bytes), isNull);
      expect(HashVerifier.verifyBytes(bytes, sha1: '', sha512: null), isNull);
    });

    test('rejects mismatches', () {
      expect(HashVerifier.verifyBytes(bytes, sha1: 'deadbeef'), contains('SHA-1'));
      expect(HashVerifier.verifyBytes(bytes, sha512: 'deadbeef'), contains('SHA-512'));
    });

    test('verifyFile streams from disk', () async {
      final dir = Directory.systemTemp.createTempSync('nuvio_hash_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'a.bin'))..writeAsBytesSync(bytes);
      expect(await HashVerifier.verifyFile(file, sha1: sha1, sha512: sha512), isNull);
      expect(await HashVerifier.verifyFile(file, sha1: 'bad'), contains('SHA-1'));
    });
  });

  group('install paths', () {
    test('each category maps to its instance folder', () {
      String? t(ContentCategory c) => ContentInstaller.targetPath('inst', c);
      expect(t(ContentCategory.mod), p.join('inst', 'mods'));
      expect(t(ContentCategory.shader), p.join('inst', 'shaderpacks'));
      expect(t(ContentCategory.resourcePack), p.join('inst', 'resourcepacks'));
      expect(t(ContentCategory.world), p.join('inst', 'saves'));
      expect(t(ContentCategory.modpack), isNull);
      expect(ContentCategory.modpack.installable, isFalse);
    });

    test('sanitizeFileName strips directories and bad characters', () {
      expect(ContentInstaller.sanitizeFileName('../../evil.jar'), 'evil.jar');
      expect(ContentInstaller.sanitizeFileName('a:b?.jar'), 'a_b_.jar');
      expect(ContentInstaller.sanitizeFileName('..'), 'download.bin');
    });

    test('install downloads, verifies and writes into mods/', () async {
      final dir = Directory.systemTemp.createTempSync('nuvio_inst_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final payload = utf8.encode('jar-bytes');
      final installer = ContentInstaller(
        client: MockClient((_) async => http.Response.bytes(payload, 200)),
        appVersion: '1.0.0',
      );
      final path = await installer.install(
        instanceDir: dir,
        category: ContentCategory.mod,
        file: ContentFile(
          filename: 'x.jar',
          url: 'https://cdn.example/x.jar',
          sha1: crypto.sha1.convert(payload).toString(),
        ),
      );
      expect(path, p.join(dir.path, 'mods', 'x.jar'));
      expect(File(path).readAsBytesSync(), payload);
      expect(File('$path.part').existsSync(), isFalse);
    });

    test('install rejects a hash mismatch and leaves nothing behind', () async {
      final dir = Directory.systemTemp.createTempSync('nuvio_inst_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final installer = ContentInstaller(
        client: MockClient((_) async => http.Response.bytes(utf8.encode('data'), 200)),
        appVersion: '1.0.0',
      );
      await expectLater(
        installer.install(
          instanceDir: dir,
          category: ContentCategory.shader,
          file: const ContentFile(
            filename: 's.zip',
            url: 'https://cdn.example/s.zip',
            sha1: 'deadbeef',
          ),
        ),
        throwsA(isA<ContentException>()),
      );
      expect(Directory(p.join(dir.path, 'shaderpacks')).listSync(), isEmpty);
    });

    test('null download URL throws with the page URL as fallback', () async {
      final dir = Directory.systemTemp.createTempSync('nuvio_inst_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final installer = ContentInstaller(
        client: MockClient((_) async => http.Response('', 500)),
        appVersion: '1.0.0',
      );
      try {
        await installer.install(
          instanceDir: dir,
          category: ContentCategory.mod,
          file: const ContentFile(filename: 'm.jar'),
          pageUrl: 'https://www.curseforge.com/minecraft/mc-mods/m',
        );
        fail('expected ContentException');
      } on ContentException catch (e) {
        expect(e.openUrl, 'https://www.curseforge.com/minecraft/mc-mods/m');
      }
    });
  });
}
