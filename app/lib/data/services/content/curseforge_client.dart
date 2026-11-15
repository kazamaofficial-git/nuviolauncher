import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/content/content_models.dart';
import '../../models/instance.dart';
import 'content_config.dart';
import 'content_provider.dart';
import 'json_util.dart';

/// CurseForge Core API (needs an API key).
class CurseForgeClient implements ContentProvider {
  CurseForgeClient({
    required http.Client client,
    required String apiKey,
    required String appVersion,
    this.host = 'api.curseforge.com',
  })  : _client = client,
        _headers = {
          'x-api-key': apiKey,
          'User-Agent': ContentConfig.userAgent(appVersion),
          'Accept': 'application/json',
        };

  static const int gameId = 432;

  final http.Client _client;
  final Map<String, String> _headers;
  final String host;

  @override
  ContentProviderId get id => ContentProviderId.curseForge;

  @override
  bool supports(ContentCategory category) => true;

  /// CurseForge `modLoaderType` id for [loader], or null when not applicable.
  static int? loaderId(LoaderType? loader) {
    switch (loader) {
      case LoaderType.forge:
        return 1;
      case LoaderType.fabric:
        return 4;
      case LoaderType.quilt:
        return 5;
      case LoaderType.neoforge:
        return 6;
      case LoaderType.vanilla:
      case null:
        return null;
    }
  }

  Future<Object?> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ContentException('Could not reach CurseForge: $e');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ContentException('CurseForge rejected the API key.');
    }
    if (response.statusCode != 200) {
      throw ContentException('CurseForge returned HTTP ${response.statusCode}.');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ContentException('CurseForge returned an unreadable response.');
    }
  }

  @override
  Future<ContentSearchResult> search(ContentQuery query) async {
    final text = query.text.trim();
    final version = query.effectiveGameVersion;
    final loader = loaderId(query.effectiveLoader);
    final uri = Uri.https(host, '/v1/mods/search', {
      'gameId': '$gameId',
      'classId': '${query.category.curseForgeClassId}',
      if (text.isNotEmpty) 'searchFilter': text,
      if (version != null) 'gameVersion': version,
      if (loader != null) 'modLoaderType': '$loader',
      'sortField': text.isEmpty ? '2' : '1',
      'sortOrder': 'desc',
      'pageSize': '${query.limit}',
      'index': '${query.offset}',
    });
    return parseSearch(asMap(await _getJson(uri)), query.category);
  }

  /// Parses a `/mods/search` response body.
  static ContentSearchResult parseSearch(Map<String, dynamic> json, ContentCategory category) {
    final projects = <ContentProject>[];
    for (final raw in asList(json['data'])) {
      final m = asMap(raw);
      final modId = m['id'];
      if (modId is! num) continue;
      final authors = asList(m['authors']).map((a) => asString(asMap(a)['name'])).where((n) => n.isNotEmpty);
      final logo = asMap(m['logo']);
      final icon = asString(logo['thumbnailUrl'], asString(logo['url']));
      final links = asMap(m['links']);
      final web = asString(links['websiteUrl']);
      projects.add(ContentProject(
        provider: ContentProviderId.curseForge,
        category: category,
        id: '${modId.toInt()}',
        slug: asString(m['slug']),
        title: asString(m['name'], asString(m['slug'])),
        author: authors.isEmpty ? '' : authors.first,
        description: asString(m['summary']),
        iconUrl: icon.isEmpty ? null : icon,
        downloads: asInt(m['downloadCount']),
        pageUrl: web.isEmpty ? null : web,
      ));
    }
    final page = asMap(json['pagination']);
    return ContentSearchResult(
      projects: projects,
      total: asInt(page['totalCount']),
      offset: asInt(page['index']),
    );
  }

  @override
  Future<String> fetchDescription(ContentProject project) async {
    try {
      final json = asMap(await _getJson(Uri.https(host, '/v1/mods/${project.id}/description')));
      final text = stripHtml(asString(json['data']));
      return text.isEmpty ? project.description : text;
    } on ContentException {
      return project.description;
    }
  }

  /// Crude HTML to text conversion for CurseForge descriptions.
  static String stripHtml(String html) {
    var s = html
        .replaceAll(RegExp(r'<(br|/p|/div|/li|/h[1-6])\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  @override
  Future<List<ContentVersion>> versions(
    ContentProject project, {
    String? gameVersion,
    LoaderType? loader,
  }) async {
    final version = gameVersion?.trim() ?? '';
    final loaderParam = project.category.supportsLoader ? loaderId(loader) : null;
    final uri = Uri.https(host, '/v1/mods/${project.id}/files', {
      if (version.isNotEmpty) 'gameVersion': version,
      if (loaderParam != null) 'modLoaderType': '$loaderParam',
      'pageSize': '50',
    });
    return parseFiles(asMap(await _getJson(uri)));
  }

  static const Set<String> _loaderNames = {'forge', 'fabric', 'quilt', 'neoforge'};

  /// Parses a `/mods/{id}/files` response body. `downloadUrl` may be null.
  static List<ContentVersion> parseFiles(Map<String, dynamic> json) {
    final out = <ContentVersion>[];
    for (final raw in asList(json['data'])) {
      final f = asMap(raw);
      final fileId = f['id'];
      if (fileId is! num) continue;
      String? sha1;
      for (final h in asList(f['hashes']).map(asMap)) {
        if (asInt(h['algo']) == 1) sha1 = asString(h['value']);
      }
      final tags = asStringList(f['gameVersions']);
      final url = f['downloadUrl'];
      final name = asString(f['fileName']);
      out.add(ContentVersion(
        id: '${fileId.toInt()}',
        name: asString(f['displayName'], name),
        versionNumber: name,
        gameVersions: tags.where((t) => RegExp(r'^\d').hasMatch(t)).toList(),
        loaders: tags.map((t) => t.toLowerCase()).where(_loaderNames.contains).toList(),
        file: ContentFile(
          filename: name.isEmpty ? '${fileId.toInt()}.jar' : name,
          url: url is String && url.isNotEmpty ? url : null,
          sha1: sha1 == null || sha1.isEmpty ? null : sha1,
          size: f['fileLength'] is num ? (f['fileLength'] as num).toInt() : null,
        ),
        datePublished: DateTime.tryParse(asString(f['fileDate'])),
      ));
    }
    return out;
  }
}
