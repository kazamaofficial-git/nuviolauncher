import '../instance.dart';

/// Where project listings come from.
enum ContentProviderId {
  modrinth('Modrinth'),
  curseForge('CurseForge');

  const ContentProviderId(this.label);

  final String label;
}

/// A browsable kind of content.
enum ContentCategory {
  mod('Mods', 'mod', 6, 'mods'),
  shader('Shaders', 'shader', 6552, 'shaderpacks'),
  resourcePack('Resource Packs', 'resourcepack', 12, 'resourcepacks'),
  modpack('Modpacks', 'modpack', 4471, null),
  world('Worlds', null, 17, 'saves');

  const ContentCategory(
    this.label,
    this.modrinthType,
    this.curseForgeClassId,
    this.installFolder,
  );

  final String label;

  /// Modrinth `project_type`, or null when Modrinth has no such category.
  final String? modrinthType;
  final int curseForgeClassId;

  /// Folder inside the instance directory, or null when not installable yet.
  final String? installFolder;

  /// Loader filters only make sense for mods.
  bool get supportsLoader => this == ContentCategory.mod;

  /// Modpacks (.mrpack) can be browsed but not installed in this beta.
  bool get installable => installFolder != null;
}

/// A mod / pack / world listing entry.
class ContentProject {
  const ContentProject({
    required this.provider,
    required this.category,
    required this.id,
    required this.title,
    this.slug = '',
    this.author = '',
    this.description = '',
    this.iconUrl,
    this.downloads = 0,
    this.pageUrl,
  });

  final ContentProviderId provider;
  final ContentCategory category;
  final String id;
  final String slug;
  final String title;
  final String author;
  final String description;
  final String? iconUrl;
  final int downloads;

  /// Public web page of the project (used for "Open on ...").
  final String? pageUrl;
}

/// A downloadable file of a [ContentVersion].
class ContentFile {
  const ContentFile({
    required this.filename,
    this.url,
    this.sha1,
    this.sha512,
    this.size,
  });

  final String filename;

  /// Null when the author disabled third-party downloads (CurseForge).
  final String? url;
  final String? sha1;
  final String? sha512;
  final int? size;
}

/// One release of a project.
class ContentVersion {
  const ContentVersion({
    required this.id,
    required this.name,
    required this.gameVersions,
    required this.loaders,
    this.versionNumber = '',
    this.file,
    this.datePublished,
  });

  final String id;
  final String name;
  final String versionNumber;
  final List<String> gameVersions;
  final List<String> loaders;
  final ContentFile? file;
  final DateTime? datePublished;
}

/// Search parameters.
class ContentQuery {
  const ContentQuery({
    required this.category,
    this.text = '',
    this.gameVersion,
    this.loader,
    this.offset = 0,
    this.limit = 20,
  });

  final ContentCategory category;
  final String text;

  /// Null or empty means "any version".
  final String? gameVersion;

  /// Null or [LoaderType.vanilla] means "any loader".
  final LoaderType? loader;
  final int offset;
  final int limit;

  String? get effectiveGameVersion {
    final v = gameVersion?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  LoaderType? get effectiveLoader =>
      category.supportsLoader && loader != null && loader != LoaderType.vanilla
          ? loader
          : null;

  ContentQuery copyWith({int? offset}) => ContentQuery(
        category: category,
        text: text,
        gameVersion: gameVersion,
        loader: loader,
        offset: offset ?? this.offset,
        limit: limit,
      );
}

/// One page of search hits.
class ContentSearchResult {
  const ContentSearchResult({
    required this.projects,
    required this.total,
    required this.offset,
  });

  final List<ContentProject> projects;
  final int total;
  final int offset;

  bool get hasMore => offset + projects.length < total && projects.isNotEmpty;
}

/// Error shown to the user; [openUrl] offers a browser fallback.
class ContentException implements Exception {
  const ContentException(this.message, {this.openUrl});

  final String message;
  final String? openUrl;

  @override
  String toString() => message;
}
