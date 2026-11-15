import '../../models/rule_environment.dart';
import '../../models/version_detail.dart';

/// Assembles the JVM + game argument list for a version.
abstract final class LaunchArgsBuilder {
  /// Returns `[extraJvm..., versionJvm..., mainClass, game...]` with all
  /// `${placeholders}` replaced from [vars]. Supports both the modern
  /// `arguments` format and the legacy `minecraftArguments` string.
  static List<String> build({
    required VersionDetail detail,
    required RuleEnvironment env,
    required Map<String, String> vars,
    List<String> extraJvmArgs = const [],
  }) {
    final jvm = <String>[];
    if (detail.jvmArgs.isNotEmpty) {
      for (final entry in detail.jvmArgs) {
        if (rulesAllow(entry.rules, env)) jvm.addAll(entry.values);
      }
    } else {
      jvm.addAll(const [
        r'-Djava.library.path=${natives_directory}',
        r'-Dminecraft.launcher.brand=${launcher_name}',
        r'-Dminecraft.launcher.version=${launcher_version}',
        '-cp',
        r'${classpath}',
      ]);
    }

    final game = <String>[];
    if (detail.gameArgs.isNotEmpty) {
      for (final entry in detail.gameArgs) {
        if (rulesAllow(entry.rules, env)) game.addAll(entry.values);
      }
    } else if (detail.legacyGameArgs != null) {
      game.addAll(detail.legacyGameArgs!.split(' ').where((s) => s.isNotEmpty));
    }

    return [
      ...extraJvmArgs,
      ...jvm.map((a) => substitute(a, vars)),
      detail.mainClass,
      ...game.map((a) => substitute(a, vars)),
    ];
  }

  /// Replaces `${key}` with `vars[key]` (unknown keys become empty).
  static String substitute(String input, Map<String, String> vars) =>
      input.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (m) => vars[m.group(1)] ?? '');
}
