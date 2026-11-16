/// Merges a mod-loader version profile (`inheritsFrom`) onto its parent (vanilla) version JSON,
/// the same way the official launcher does.
Map<String, dynamic> mergeVersionJson(Map<String, dynamic> parent, Map<String, dynamic> child) {
  final merged = <String, dynamic>{...parent, ...child}..remove('inheritsFrom');

  String key(Map<String, dynamic> lib) {
    final parts = (lib['name'] as String? ?? '').split(':');
    if (parts.length < 3) return parts.join(':');
    // group:artifact[:classifier] - the version is what the child overrides.
    return [parts[0], parts[1], if (parts.length > 3) parts[3]].join(':');
  }

  final childLibs = (child['libraries'] as List? ?? const []).cast<Map<String, dynamic>>();
  final parentLibs = (parent['libraries'] as List? ?? const []).cast<Map<String, dynamic>>();
  final seen = childLibs.map(key).toSet();
  merged['libraries'] = [
    ...childLibs,
    ...parentLibs.where((l) => !seen.contains(key(l))),
  ];

  final pArgs = parent['arguments'] as Map<String, dynamic>?;
  final cArgs = child['arguments'] as Map<String, dynamic>?;
  if (pArgs != null || cArgs != null) {
    merged['arguments'] = {
      'jvm': [...(pArgs?['jvm'] as List? ?? const []), ...(cArgs?['jvm'] as List? ?? const [])],
      'game': [...(pArgs?['game'] as List? ?? const []), ...(cArgs?['game'] as List? ?? const [])],
    };
  }
  // A child with its own legacy argument string replaces the parent's.
  if (child['minecraftArguments'] == null && parent['minecraftArguments'] != null && cArgs != null) {
    merged.remove('minecraftArguments');
  }
  return merged;
}
