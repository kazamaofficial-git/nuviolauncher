import 'dart:io';

/// Describes the machine for evaluating Mojang "rules" arrays.
class RuleEnvironment {
  const RuleEnvironment({
    required this.osName,
    this.arch = 'x86_64',
    this.features = const <String>{},
    this.osVersion,
  });

  /// Mojang OS name: `windows`, `linux` or `osx`.
  final String osName;

  /// `x86_64`, `x86` or `arm64`.
  final String arch;

  /// Enabled launcher features (none are enabled by this launcher).
  final Set<String> features;

  /// When null, OS version regexes in rules are treated as matching.
  final String? osVersion;

  /// `32` or `64`, used for the `${arch}` placeholder in natives classifiers.
  String get bits => arch == 'x86' ? '32' : '64';

  factory RuleEnvironment.current() {
    final os = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
            ? 'osx'
            : 'linux';
    final procArch = (Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '').toUpperCase();
    return RuleEnvironment(
      osName: os,
      arch: procArch == 'ARM64' ? 'arm64' : 'x86_64',
    );
  }
}

/// Evaluates a Mojang `rules` list. No rules means allowed; otherwise the
/// last matching rule decides and the default is "disallow".
bool rulesAllow(List<dynamic>? rules, RuleEnvironment env) {
  if (rules == null || rules.isEmpty) return true;
  var allowed = false;
  for (final rule in rules) {
    if (rule is! Map) continue;
    if (_ruleMatches(rule, env)) {
      allowed = rule['action'] == 'allow';
    }
  }
  return allowed;
}

bool _ruleMatches(Map<dynamic, dynamic> rule, RuleEnvironment env) {
  final os = rule['os'];
  if (os is Map) {
    final name = os['name'];
    if (name != null && name != env.osName) return false;
    final arch = os['arch'];
    if (arch != null && arch != env.arch) return false;
    final version = os['version'];
    if (version is String && env.osVersion != null) {
      if (!RegExp(version).hasMatch(env.osVersion!)) return false;
    }
  }
  final features = rule['features'];
  if (features is Map) {
    for (final entry in features.entries) {
      final wanted = entry.value == true;
      final have = env.features.contains(entry.key.toString());
      if (wanted != have) return false;
    }
  }
  return true;
}
