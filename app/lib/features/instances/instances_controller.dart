import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/instance.dart';
import '../../data/repositories/instance_repository.dart';
import '../license/license_controller.dart';

/// CRUD and selection for game instances, enforcing the free-plan limit.
class InstancesController extends ChangeNotifier {
  InstancesController({
    required InstanceRepository repository,
    required LicenseController license,
  })  : _repository = repository,
        _license = license,
        _items = repository.load(),
        _selectedId = repository.loadSelected() {
    _license.addListener(notifyListeners);
  }

  final InstanceRepository _repository;
  final LicenseController _license;
  final List<Instance> _items;
  String? _selectedId;

  List<Instance> get items => List.unmodifiable(_items);

  String? get selectedId => selected?.id;

  Instance? get selected {
    if (_items.isEmpty) return null;
    return _items.firstWhere((e) => e.id == _selectedId, orElse: () => _items.first);
  }

  bool get canCreate =>
      _license.hasPlus || _items.length < AppConstants.freeInstanceLimit;

  Future<Instance?> create({
    required String name,
    required String versionId,
    required LoaderType loader,
    required String renderer,
    required int ramMb,
    required String jvmArgs,
    String? loaderVersion,
  }) async {
    if (!canCreate) return null;
    final instance = Instance(
      id: const Uuid().v4(),
      name: name,
      versionId: versionId,
      loader: loader,
      renderer: renderer,
      ramMb: ramMb,
      jvmArgs: jvmArgs,
      createdAt: DateTime.now(),
      loaderVersion: loaderVersion,
    );
    _items.add(instance);
    _selectedId ??= instance.id;
    await _persist();
    return instance;
  }

  Future<void> update(Instance instance) async {
    final i = _items.indexWhere((e) => e.id == instance.id);
    if (i < 0) return;
    _items[i] = instance;
    await _persist();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    if (_selectedId == id) _selectedId = _items.isEmpty ? null : _items.first.id;
    await _persist();
  }

  Future<void> select(String id) async {
    _selectedId = id;
    notifyListeners();
    await _repository.saveSelected(id);
  }

  Future<void> markPlayed(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(lastPlayed: DateTime.now());
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _repository.save(_items);
    await _repository.saveSelected(_selectedId);
  }

  @override
  void dispose() {
    _license.removeListener(notifyListeners);
    super.dispose();
  }
}
