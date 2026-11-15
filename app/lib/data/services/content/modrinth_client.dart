import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/content/content_models.dart';
import '../../models/instance.dart';
import 'content_config.dart';
import 'content_provider.dart';
import 'json_util.dart';

/// Modrinth API v2 (no key required).
class ModrinthClient implements ContentProvider {
  ModrinthClient({
    required http.Client client,
    required String appVersion,
    this.host = 'api.modrinth.com',
  })  : _client = client,
        _headers = {
          'User-Agent': ContentConfig.userAgent(appVersion),
          'Accept': 'application/json',
        };

  final http.Client _client;
  final Map<String, String> _headers;
  final String host;

  @override
  ContentProviderId get id => ContentProviderId.modrinth;

  @override
  bool supports(ContentCategory category) => category.modrinthType != null;

  /// Builds the `facets` query value, e.g. `[["project_type:mod"],["versions:1.21"]]`.
  static String buildFacets(ContentQuery q) {
    final facets = <List<String>>[
      ['project_type:${q.category.modrinthType}'],
    ];
    final version = q.effectiveGameVersion;
    if (version != null) facets.add(['versions:$version']);
    final loader = q.effectiveLoader;
    if (loader != null) facets.add(['categories:${loader.name}']);
    return jsonEncode(facets);
  }

  Future<Object?> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ContentException('Could not reach Modrinth: $e');
    }
    if (response.statusCode != 200) {
      throw ContentException('Modrinth returned HTTP ${response.statusCode}.');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ContentException('Modrinth returned an unreadable response.');
    }
  }

  @override
  Future<ContentSearchResult> search(ContentQuery query) async {
    if (!supports(query.category)) {
      throw const ContentException('Modrinth does not list this category.');
    }
    final text = query.text.trim();
    final uri = Uri.https(host, '/v2/search', {
      if (text.isNotEmpty) 'query': text,
      'facets': buildFacets(query),
      'index': text.isEmpty ? 'downloads' : 'relevance',
      'limit': '${query.limit}',
      'offset': '${query.offset}',
    });
    final json = asMap(await _getJson(uri));
    return parseSearch(json, query.category);
  }

  /// Parses a `/search` response body.
  static ContentSearchResult parseSearch(Map<String, dynamic> json, ContentCategory category) {
    final projects = <ContentProject>[];
    for (final raw in asList(json['hits'])) {
      final hit = asMap(raw);
      final projectId = asString(hit['project_id']);
      if (projectId.isEmpty) continue;
      final slug = asString(hit['slug']);
      final type = asString(hit['project_type'], category.modrinthType ?? 'mod');
      final icon = asString(hit['icon_url']);
      projects.add(ContentProject(
        provider: ContentProviderId.modrinth,
        category: category,
        id: projectId,
        slug: slug,
        title: asString(hit['title'], slug),
        author: asString(hit['author']),
        description: asString(hit['description']),
        iconUrl: icon.isEmpty ? null : icon,
        downloads: asInt(hit['downloads']),
        pageUrl: 'https://modrinth.com/$type/${slug.isEmpty ? projectId : slug}',
      ));
    }
    return ContentSearchResult(
      projects: projects,
      total: asInt(json['total_hits']),
      offset: asInt(json['offset']),
    );
  }

  @override
  Future<String> fetchDescription(ContentProject project) async {
    final json = asMap(await _getJson(Uri.https(host, '/v2/project/${project.id}')));
    final body = asString(json['body']);
    return body.isEmpty ? project.description : body;
  }

  @override
  Future<List<ContentVersion>> versions(
    ContentProject project, {
    String? gameVersion,
    LoaderType? loader,
  }) async {
    final version = gameVersion?.trim() ?? '';
    final useLoader =
        project.category.supportsLoader && loader != null && loader != LoaderType.vanilla;
    final uri = Uri.https(host, '/v2/project/${project.id}/version', {
      if (version.isNotEmpty) 'game_versions': jsonEncode([version]),
      if (useLoader) 'loaders': jsonEncode([loader!.name]),
    });
    return parseVersions(await _getJson(uri));
  }

  /// Parses a `/project/{id}/version` response body.
  static List<ContentVersion> parseVersions(Object? json) {
    final out = <ContentVersion>[];
    for (final raw in asList(json)) {
      final v = asMap(raw);
      final versionId = asString(v['id']);
      if (versionId.isEmpty) continue;
      final files = asList(v['files']).map(asMap).toList();
      Map<String, dynamic>? chosen;
      for (final f in files) {
        if (f['primary'] == true) {
          chosen = f;
          break;
        }
      }
      chosen ??= files.isEmpty ? null : files.first;
      ContentFile? file;
      if (chosen != null) {
        final hashes = asMap(chosen['hashes']);
        final sha1 = asString(hashes['sha1']);
        final sha512 = asString(hashes['sha512']);
        final url = asString(chosen['url']);
        file = ContentFile(
          filename: asString(chosen['filename'], '$versionId.jar'),
          url: url.isEmpty ? null : url,
          sha1: sha1.isEmpty ? null : sha1,
          sha512: sha512.isEmpty ? null : sha512,
          size: chosen['size'] is num ? (chosen['size'] as num).toInt() : null,
        );
      }
      out.add(ContentVersion(
        id: versionId,
        name: asString(v['name'], asString(v['version_number'])),
        versionNumber: asString(v['version_number']),
        gameVersions: asStringList(v['game_versions']),
        loaders: asStringList(v['loaders']),
        file: file,
        datePublished: DateTime.tryParse(asString(v['date_published'])),
      ));
    }
    return out;
  }
}
