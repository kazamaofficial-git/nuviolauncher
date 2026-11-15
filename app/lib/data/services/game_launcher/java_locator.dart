import 'dart:io';

import 'package:path/path.dart' as p;

/// Finds a Java executable and detects its major version.
abstract final class JavaLocator {
  /// Resolution order: configured path, `JAVA_HOME`, then `java` on `PATH`.
  /// Returns null when nothing usable is found.
  static Future<String?> find({String? configured}) async {
    if (configured != null && configured.trim().isNotEmpty) {
      final file = File(configured.trim());
      return await file.exists() ? file.path : null;
    }

    final home = Platform.environment['JAVA_HOME'];
    if (home != null && home.isNotEmpty) {
      final exe = p.join(home, 'bin', Platform.isWindows ? 'java.exe' : 'java');
      if (await File(exe).exists()) return exe;
    }

    try {
      final result = await Process.run('java', ['-version']);
      if (result.exitCode == 0) return 'java';
    } on ProcessException {
      // Not on PATH.
    }
    return null;
  }

  /// Runs `java -version` and returns the major version, or null if unknown.
  static Future<int?> detectMajor(String javaExecutable) async {
    try {
      final result = await Process.run(javaExecutable, ['-version']);
      return parseJavaMajor('${result.stderr}\n${result.stdout}');
    } on ProcessException {
      return null;
    }
  }
}

/// Parses `java -version` output: `"17.0.2"` -> 17, `"1.8.0_362"` -> 8.
int? parseJavaMajor(String output) {
  final match = RegExp(r'version "(\d+)(?:\.(\d+))?').firstMatch(output);
  if (match == null) return null;
  final first = int.parse(match.group(1)!);
  if (first == 1) return int.tryParse(match.group(2) ?? '');
  return first;
}
