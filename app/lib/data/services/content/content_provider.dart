import '../../models/content/content_models.dart';
import '../../models/instance.dart';

/// A source of mods, packs and worlds.
abstract class ContentProvider {
  ContentProviderId get id;

  /// Whether this provider lists [category].
  bool supports(ContentCategory category);

  Future<ContentSearchResult> search(ContentQuery query);

  /// Long description as plain text (markdown or stripped HTML).
  Future<String> fetchDescription(ContentProject project);

  /// Versions of [project], newest first, optionally filtered.
  Future<List<ContentVersion>> versions(
    ContentProject project, {
    String? gameVersion,
    LoaderType? loader,
  });
}
