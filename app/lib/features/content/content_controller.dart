import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/content/content_models.dart';
import '../../data/models/instance.dart';
import '../../data/services/content/content_config.dart';
import '../../data/services/content/content_installer.dart';
import '../../data/services/content/content_provider.dart';
import '../../data/services/content/curseforge_client.dart';
import '../../data/services/content/installed_content_service.dart';
import '../../data/services/content/modrinth_client.dart';
import '../instances/instances_controller.dart';
import '../settings/settings_controller.dart';

/// State of the Content Hub: provider, category, filters, paged results,
/// installs into the selected instance and the "installed" listing.
class ContentController extends ChangeNotifier {
  ContentController({
    required InstancesController instances,
    required SettingsController settings,
    required String appVersion,
    http.Client? client,
    Map<ContentProviderId, ContentProvider>? providers,
    ContentInstaller? installer,
    this.debounce = const Duration(milliseconds: 400),
  })  : _instances = instances,
        _settings = settings {
    final httpClient = client ?? http.Client();
    _providers = providers ??
        {
          ContentProviderId.modrinth: ModrinthClient(client: httpClient, appVersion: appVersion),
          if (ContentConfig.curseForgeEnabled)
            ContentProviderId.curseForge: CurseForgeClient(
              client: httpClient,
              apiKey: ContentConfig.curseForgeApiKey,
              appVersion: appVersion,
            ),
        };
    _installer = installer ?? ContentInstaller(client: httpClient, appVersion: appVersion);
    _lastInstanceId = instances.selected?.id;
    _applyInstanceDefaults();
    _instances.addListener(_onInstancesChanged);
  }

  final InstancesController _instances;
  final SettingsController _settings;
  final Duration debounce;
  late final Map<ContentProviderId, ContentProvider> _providers;
  late final ContentInstaller _installer;

  Timer? _debounceTimer;
  String? _lastInstanceId;
  int _requestToken = 0;
  bool _loadedOnce = false;
  bool _disposed = false;

  ContentCategory _category = ContentCategory.mod;
  ContentProviderId _providerId = ContentProviderId.modrinth;
  String _text = '';
  String _gameVersion = '';
  LoaderType _loader = LoaderType.vanilla;

  final List<ContentProject> _results = [];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  ContentCategory get category => _category;
  ContentProviderId get providerId => _providerId;
  String get text => _text;
  String get gameVersion => _gameVersion;

  /// [LoaderType.vanilla] means "any loader" in the filter.
  LoaderType get loader => _loader;
  List<ContentProject> get results => List.unmodifiable(_results);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _results.isNotEmpty && _results.length < _total;
  Instance? get selectedInstance => _instances.selected;

  bool isProviderAvailable(ContentProviderId id) => _providers.containsKey(id);
  bool get curseForgeAvailable => isProviderAvailable(ContentProviderId.curseForge);

  ContentProvider? get _provider => _providers[_providerId];

  /// Null when the current provider/category combination can be browsed.
  String? get unsupportedMessage {
    final provider = _provider;
    if (provider == null) {
      return 'CurseForge is not configured. Build with --dart-define=CURSEFORGE_API_KEY=...';
    }
    if (!provider.supports(_category)) {
      return '${_category.label} are only available on CurseForge.';
    }
    return null;
  }

  void _applyInstanceDefaults() {
    final instance = _instances.selected;
    _gameVersion = instance?.versionId ?? '';
    _loader = instance?.loader ?? LoaderType.vanilla;
  }

  void _onInstancesChanged() {
    final id = _instances.selected?.id;
    if (id == _lastInstanceId) return;
    _lastInstanceId = id;
    _applyInstanceDefaults();
    notifyListeners();
    if (_loadedOnce) unawaited(refresh());
  }

  /// Loads the first page the first time the hub is shown.
  void ensureLoaded() {
    if (_loadedOnce) return;
    _loadedOnce = true;
    // Deferred: this is called from a build method.
    unawaited(Future<void>.microtask(refresh));
  }

  void setCategory(ContentCategory value) {
    if (value == _category) return;
    _category = value;
    _scheduleRefresh(immediately: true);
  }

  void setProvider(ContentProviderId value) {
    if (value == _providerId || !isProviderAvailable(value)) return;
    _providerId = value;
    _scheduleRefresh(immediately: true);
  }

  void setText(String value) {
    if (value == _text) return;
    _text = value;
    _scheduleRefresh();
  }

  void setGameVersion(String value) {
    if (value == _gameVersion) return;
    _gameVersion = value;
    _scheduleRefresh();
  }

  void setLoader(LoaderType value) {
    if (value == _loader) return;
    _loader = value;
    _scheduleRefresh(immediately: true);
  }

  void _scheduleRefresh({bool immediately = false}) {
    _debounceTimer?.cancel();
    notifyListeners();
    if (immediately) {
      unawaited(refresh());
    } else {
      _debounceTimer = Timer(debounce, () => unawaited(refresh()));
    }
  }

  ContentQuery _query(int offset) => ContentQuery(
        category: _category,
        text: _text,
        gameVersion: _gameVersion,
        loader: _loader,
        offset: offset,
      );

  /// Reloads the first page with the current filters.
  Future<void> refresh() async {
    _debounceTimer?.cancel();
    _loadedOnce = true;
    final token = ++_requestToken;
    _results.clear();
    _total = 0;
    _error = null;
    _loadingMore = false;
    final provider = _provider;
    if (provider == null || !provider.supports(_category)) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final page = await provider.search(_query(0));
      if (token != _requestToken || _disposed) return;
      _results.addAll(page.projects);
      _total = page.total;
    } on ContentException catch (e) {
      if (token != _requestToken || _disposed) return;
      _error = e.message;
    } catch (e) {
      if (token != _requestToken || _disposed) return;
      _error = 'Something went wrong: $e';
    }
    _loading = false;
    notifyListeners();
  }

  /// Appends the next page of results.
  Future<void> loadMore() async {
    final provider = _provider;
    if (provider == null || _loading || _loadingMore || !hasMore) return;
    final token = _requestToken;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await provider.search(_query(_results.length));
      if (token != _requestToken || _disposed) return;
      _results.addAll(page.projects);
      _total = page.total;
      if (page.projects.isEmpty) _total = _results.length;
    } on ContentException catch (e) {
      if (token == _requestToken && !_disposed) _error = e.message;
    } catch (e) {
      if (token == _requestToken && !_disposed) _error = 'Something went wrong: $e';
    }
    if (token == _requestToken && !_disposed) {
      _loadingMore = false;
      notifyListeners();
    }
  }

  ContentProvider _providerFor(ContentProject project) {
    final provider = _providers[project.provider];
    if (provider == null) {
      throw ContentException('${project.provider.label} is not available.');
    }
    return provider;
  }

  Future<String> loadDescription(ContentProject project) =>
      _providerFor(project).fetchDescription(project);

  /// Versions of [project]; pass [applyFilters] false to list every version.
  Future<List<ContentVersion>> loadVersions(
    ContentProject project, {
    bool applyFilters = true,
  }) =>
      _providerFor(project).versions(
        project,
        gameVersion: applyFilters ? _gameVersion : null,
        loader: applyFilters ? _loader : null,
      );

  /// Directory of the selected instance (not created yet), or null if none.
  Future<Directory?> selectedInstanceDir() async {
    final instance = _instances.selected;
    if (instance == null) return null;
    return Directory(await _settings.resolveInstanceDir(instance.id));
  }

  /// Installs [version] of [project] into the selected instance.
  /// Throws [ContentException] with a user-facing message.
  Future<String> install(
    ContentProject project,
    ContentVersion version, {
    InstallProgress? onProgress,
  }) async {
    final dir = await selectedInstanceDir();
    if (dir == null) {
      throw const ContentException('Create or select an instance first.');
    }
    final file = version.file;
    if (file == null) {
      throw const ContentException('This version has no downloadable file.');
    }
    try {
      return await _installer.install(
        instanceDir: dir,
        category: project.category,
        file: file,
        pageUrl: project.pageUrl,
        onProgress: onProgress,
      );
    } on ContentException {
      rethrow;
    } on FileSystemException catch (e) {
      throw ContentException('Could not write the file: ${e.message}');
    }
  }

  Future<List<InstalledFile>> listInstalled() async {
    final dir = await selectedInstanceDir();
    if (dir == null) return const [];
    return InstalledContentService.list(dir);
  }

  Future<void> deleteInstalled(InstalledFile file) => InstalledContentService.delete(file);

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _instances.removeListener(_onInstancesChanged);
    super.dispose();
  }
}
